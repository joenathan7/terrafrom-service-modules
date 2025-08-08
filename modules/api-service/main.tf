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

resource "google_compute_instance_template" "api_template" {
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
    apt-get install -y docker.io
    systemctl start docker
    systemctl enable docker
  EOF

  lifecycle {
    create_before_destroy = true
  }
}

resource "google_compute_instance_group_manager" "api_group" {
  name               = "${var.service_name}-group"
  base_instance_name = var.service_name
  zone               = "${var.region}-a"
  project            = var.project_id

  version {
    instance_template = google_compute_instance_template.api_template.id
  }

  target_size = 2

  named_port {
    name = "http"
    port = 8080
  }
}

resource "google_compute_backend_service" "api_backend" {
  name        = "${var.service_name}-backend"
  protocol    = "HTTP"
  port_name   = "http"
  timeout_sec = 10
  project     = var.project_id

  backend {
    group = google_compute_instance_group_manager.api_group.instance_group
  }

  health_checks = [google_compute_health_check.api_health_check.id]
}

resource "google_compute_health_check" "api_health_check" {
  name               = "${var.service_name}-health-check"
  timeout_sec        = 5
  check_interval_sec = 5
  project            = var.project_id

  http_health_check {
    port = 8080
  }
}

resource "google_compute_url_map" "api_url_map" {
  name            = "${var.service_name}-url-map"
  default_service = google_compute_backend_service.api_backend.id
  project         = var.project_id
}

resource "google_compute_target_http_proxy" "api_proxy" {
  name    = "${var.service_name}-proxy"
  url_map = google_compute_url_map.api_url_map.id
  project = var.project_id
}

resource "google_compute_global_forwarding_rule" "api_forwarding_rule" {
  name       = "${var.service_name}-forwarding-rule"
  target     = google_compute_target_http_proxy.api_proxy.id
  port_range = "80"
  project    = var.project_id
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

# Outputs
output "service_repository_url" {
  description = "URL of the created service repository"
  value       = local.service_repo_url
}

output "infrastructure_repository_url" {
  description = "URL of the created infrastructure repository"
  value       = local.infrastructure_repo_url
}

output "load_balancer_ip" {
  description = "IP address of the load balancer"
  value       = google_compute_global_forwarding_rule.api_forwarding_rule.ip_address
}

output "instance_group_name" {
  description = "Name of the instance group"
  value       = google_compute_instance_group_manager.api_group.name
} 