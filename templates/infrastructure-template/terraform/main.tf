terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }
}

# Provider configuration
provider "google" {
  project = var.project_id
  region  = var.region
}

# Variables
variable "project_id" {
  description = "Google Cloud Project ID"
  type        = string
}

variable "region" {
  description = "Google Cloud region"
  type        = string
  default     = "us-central1"
}

variable "environment" {
  description = "Environment (dev, staging, production)"
  type        = string
  default     = "dev"
}

variable "service_name" {
  description = "Name of the microservice"
  type        = string
}

# Local values
locals {
  common_labels = {
    environment = var.environment
    service     = var.service_name
    managed_by  = "terraform"
  }
}

# VPC Network
resource "google_compute_network" "vpc" {
  name                    = "${var.service_name}-vpc"
  auto_create_subnetworks = false
  project                 = var.project_id

  labels = local.common_labels
}

# Subnet
resource "google_compute_subnetwork" "subnet" {
  name          = "${var.service_name}-subnet"
  ip_cidr_range = "10.0.0.0/24"
  network       = google_compute_network.vpc.id
  region        = var.region
  project       = var.project_id

  labels = local.common_labels
}

# Firewall rules
resource "google_compute_firewall" "allow_http" {
  name    = "${var.service_name}-allow-http"
  network = google_compute_network.vpc.name
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["http-server"]

  labels = local.common_labels
}

resource "google_compute_firewall" "allow_https" {
  name    = "${var.service_name}-allow-https"
  network = google_compute_network.vpc.name
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["https-server"]

  labels = local.common_labels
}

resource "google_compute_firewall" "allow_ssh" {
  name    = "${var.service_name}-allow-ssh"
  network = google_compute_network.vpc.name
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["ssh"]

  labels = local.common_labels
}

# Service Account
resource "google_service_account" "service_account" {
  account_id   = "${var.service_name}-sa"
  display_name = "Service Account for ${var.service_name}"
  project      = var.project_id

  labels = local.common_labels
}

# IAM roles
resource "google_project_iam_member" "compute_admin" {
  project = var.project_id
  role    = "roles/compute.admin"
  member  = "serviceAccount:${google_service_account.service_account.email}"
}

resource "google_project_iam_member" "storage_admin" {
  project = var.project_id
  role    = "roles/storage.admin"
  member  = "serviceAccount:${google_service_account.service_account.email}"
}

# Cloud Storage bucket for logs
resource "google_storage_bucket" "logs" {
  name          = "${var.service_name}-logs"
  location      = "US"
  project       = var.project_id
  force_destroy = true

  versioning {
    enabled = true
  }

  lifecycle_rule {
    condition {
      age = 30
    }
    action {
      type = "Delete"
    }
  }

  labels = local.common_labels
}

# Cloud Monitoring workspace
resource "google_monitoring_dashboard" "dashboard" {
  dashboard_json = jsonencode({
    displayName = "${var.service_name} Dashboard"
    gridLayout = {
      widgets = [
        {
          title = "CPU Usage"
          xyChart = {
            dataSets = [
              {
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "metric.type=\"compute.googleapis.com/instance/cpu/utilization\""
                  }
                }
              }
            ]
          }
        }
      ]
    }
  })
  project = var.project_id
}

# Cloud Logging sink
resource "google_logging_project_sink" "logs_sink" {
  name        = "${var.service_name}-logs-sink"
  destination = "storage.googleapis.com/${google_storage_bucket.logs.name}"
  filter      = "resource.type=gce_instance AND resource.labels.instance_name=~\"${var.service_name}.*\""
  project     = var.project_id
}

# Outputs
output "vpc_name" {
  description = "Name of the VPC"
  value       = google_compute_network.vpc.name
}

output "subnet_name" {
  description = "Name of the subnet"
  value       = google_compute_subnetwork.subnet.name
}

output "service_account_email" {
  description = "Email of the service account"
  value       = google_service_account.service_account.email
}

output "logs_bucket" {
  description = "Name of the logs bucket"
  value       = google_storage_bucket.logs.name
} 