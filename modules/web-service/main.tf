terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
    github = {
      source  = "integrations/github"
      version = "~> 5.0"
    }
  }
}

# Variables
variable "service_name" {
  description = "Name of the microservice"
  type        = string
}

variable "environment" {
  description = "Environment (dev, staging, production)"
  type        = string
  default     = "dev"
}

variable "project_id" {
  description = "Google Cloud Project ID"
  type        = string
}

variable "region" {
  description = "Google Cloud region"
  type        = string
  default     = "us-central1"
}

variable "github_token" {
  description = "GitHub Personal Access Token"
  type        = string
  sensitive   = true
}

variable "github_org" {
  description = "GitHub organization name"
  type        = string
}

variable "domain_name" {
  description = "Domain name for the web service"
  type        = string
}

# Local values
locals {
  service_repo_name     = "${var.service_name}-service"
  infrastructure_repo_name = "${var.service_name}-infrastructure"
  service_repo_url      = "https://github.com/${var.github_org}/${local.service_repo_name}"
  infrastructure_repo_url = "https://github.com/${var.github_org}/${local.infrastructure_repo_name}"
}

# Google Cloud Resources
resource "google_compute_network" "vpc" {
  name                    = "${var.service_name}-vpc"
  auto_create_subnetworks = false
  project                 = var.project_id
}

resource "google_compute_subnetwork" "subnet" {
  name          = "${var.service_name}-subnet"
  ip_cidr_range = "10.0.0.0/24"
  network       = google_compute_network.vpc.id
  region        = var.region
  project       = var.project_id
}

resource "google_compute_instance_template" "web_template" {
  name_prefix  = "${var.service_name}-template"
  machine_type = "e2-medium"
  region       = var.region
  project      = var.project_id

  disk {
    source_image = "debian-cloud/debian-11"
    auto_delete  = true
    boot         = true
    disk_size_gb = 20
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnet.id
  }

  metadata = {
    service-name = var.service_name
    environment  = var.environment
  }

  metadata_startup_script = <<-EOF
    #!/bin/bash
    apt-get update
    apt-get install -y nginx docker.io
    systemctl start nginx
    systemctl enable nginx
    systemctl start docker
    systemctl enable docker
  EOF

  lifecycle {
    create_before_destroy = true
  }
}

resource "google_compute_instance_group_manager" "web_group" {
  name               = "${var.service_name}-group"
  base_instance_name = var.service_name
  zone               = "${var.region}-a"
  project            = var.project_id

  version {
    instance_template = google_compute_instance_template.web_template.id
  }

  target_size = 2

  named_port {
    name = "http"
    port = 80
  }

  named_port {
    name = "https"
    port = 443
  }
}

resource "google_compute_backend_service" "web_backend" {
  name        = "${var.service_name}-backend"
  protocol    = "HTTP"
  port_name   = "http"
  timeout_sec = 10
  project     = var.project_id

  backend {
    group = google_compute_instance_group_manager.web_group.instance_group
  }

  health_checks = [google_compute_health_check.web_health_check.id]
}

resource "google_compute_health_check" "web_health_check" {
  name               = "${var.service_name}-health-check"
  timeout_sec        = 5
  check_interval_sec = 5
  project            = var.project_id

  http_health_check {
    port = 80
  }
}

# SSL Certificate
resource "google_compute_managed_ssl_certificate" "web_cert" {
  name    = "${var.service_name}-ssl-cert"
  project = var.project_id

  managed {
    domains = [var.domain_name]
  }
}

# URL Map with HTTPS redirect
resource "google_compute_url_map" "web_url_map" {
  name            = "${var.service_name}-url-map"
  default_service = google_compute_backend_service.web_backend.id
  project         = var.project_id

  host_rule {
    hosts        = [var.domain_name]
    path_matcher = "allpaths"
  }

  path_matcher {
    name            = "allpaths"
    default_service = google_compute_backend_service.web_backend.id
  }
}

# HTTPS Proxy
resource "google_compute_target_https_proxy" "web_https_proxy" {
  name             = "${var.service_name}-https-proxy"
  url_map          = google_compute_url_map.web_url_map.id
  ssl_certificates = [google_compute_managed_ssl_certificate.web_cert.id]
  project          = var.project_id
}

# HTTP Proxy (for redirect)
resource "google_compute_target_http_proxy" "web_http_proxy" {
  name    = "${var.service_name}-http-proxy"
  url_map = google_compute_url_map.web_url_map.id
  project = var.project_id
}

# Global forwarding rules
resource "google_compute_global_forwarding_rule" "web_https_forwarding_rule" {
  name       = "${var.service_name}-https-forwarding-rule"
  target     = google_compute_target_https_proxy.web_https_proxy.id
  port_range = "443"
  project    = var.project_id
}

resource "google_compute_global_forwarding_rule" "web_http_forwarding_rule" {
  name       = "${var.service_name}-http-forwarding-rule"
  target     = google_compute_target_http_proxy.web_http_proxy.id
  port_range = "80"
  project    = var.project_id
}

# Cloud CDN
resource "google_compute_backend_bucket" "web_cdn" {
  name        = "${var.service_name}-cdn"
  bucket_name = google_storage_bucket.web_static.name
  project     = var.project_id

  cdn_policy {
    cache_mode        = "CACHE_ALL_STATIC"
    client_ttl        = 3600
    default_ttl       = 86400
    max_ttl           = 604800
    negative_caching  = true
    serve_while_stale = 86400
  }
}

# Storage bucket for static assets
resource "google_storage_bucket" "web_static" {
  name          = "${var.service_name}-static-assets"
  location      = "US"
  project       = var.project_id
  force_destroy = true

  website {
    main_page_suffix = "index.html"
    not_found_page   = "404.html"
  }
}

# GitHub Repository Creation
resource "github_repository" "service_repo" {
  name        = local.service_repo_name
  description = "Service repository for ${var.service_name}"
  visibility  = "private"
  auto_init   = true

  template {
    owner      = var.github_org
    repository = "service-template"
  }
}

resource "github_repository" "infrastructure_repo" {
  name        = local.infrastructure_repo_name
  description = "Infrastructure repository for ${var.service_name}"
  visibility  = "private"
  auto_init   = true

  template {
    owner      = var.github_org
    repository = "infrastructure-template"
  }
} 