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

variable "queue_name" {
  description = "Name of the Pub/Sub queue"
  type        = string
  default     = "worker-queue"
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

# Pub/Sub Topic
resource "google_pubsub_topic" "worker_topic" {
  name    = "${var.service_name}-topic"
  project = var.project_id
}

# Pub/Sub Subscription
resource "google_pubsub_subscription" "worker_subscription" {
  name  = "${var.service_name}-subscription"
  topic = google_pubsub_topic.worker_topic.name
  project = var.project_id

  ack_deadline_seconds = 20

  expiration_policy {
    ttl = "2678400s" # 31 days
  }
}

# Cloud Storage bucket for worker data
resource "google_storage_bucket" "worker_data" {
  name          = "${var.service_name}-worker-data"
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
}

resource "google_compute_instance_template" "worker_template" {
  name_prefix  = "${var.service_name}-template"
  machine_type = "e2-standard-2"
  region       = var.region
  project      = var.project_id

  disk {
    source_image = "debian-cloud/debian-11"
    auto_delete  = true
    boot         = true
    disk_size_gb = 50
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnet.id
  }

  metadata = {
    service-name = var.service_name
    environment  = var.environment
    topic-name   = google_pubsub_topic.worker_topic.name
    bucket-name  = google_storage_bucket.worker_data.name
  }

  metadata_startup_script = <<-EOF
    #!/bin/bash
    apt-get update
    apt-get install -y docker.io python3-pip
    systemctl start docker
    systemctl enable docker
    
    # Install Google Cloud SDK
    echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -
    apt-get update && apt-get install -y google-cloud-sdk
    
    # Install worker dependencies
    pip3 install google-cloud-pubsub google-cloud-storage
  EOF

  service_account {
    scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "google_compute_instance_group_manager" "worker_group" {
  name               = "${var.service_name}-group"
  base_instance_name = var.service_name
  zone               = "${var.region}-a"
  project            = var.project_id

  version {
    instance_template = google_compute_instance_template.worker_template.id
  }

  target_size = 3

  auto_healing_policies {
    health_check      = google_compute_health_check.worker_health_check.id
    initial_delay_sec = 300
  }
}

resource "google_compute_health_check" "worker_health_check" {
  name               = "${var.service_name}-health-check"
  timeout_sec        = 5
  check_interval_sec = 5
  project            = var.project_id

  tcp_health_check {
    port = 8080
  }
}

# Cloud Function for queue processing (optional)
resource "google_storage_bucket" "function_bucket" {
  name          = "${var.service_name}-function-bucket"
  location      = "US"
  project       = var.project_id
  force_destroy = true
}

resource "google_storage_bucket_object" "function_archive" {
  name   = "function.zip"
  bucket = google_storage_bucket.function_bucket.name
  source = "function.zip" # This would be created by the build process
}

resource "google_cloudfunctions_function" "worker_function" {
  name        = "${var.service_name}-function"
  description = "Worker function for ${var.service_name}"
  runtime     = "python39"
  project     = var.project_id
  region      = var.region

  available_memory_mb   = 256
  source_archive_bucket = google_storage_bucket.function_bucket.name
  source_archive_object = google_storage_bucket_object.function_archive.name
  trigger_topic         = google_pubsub_topic.worker_topic.name

  entry_point = "process_message"
}

# IAM for service account
resource "google_service_account" "worker_service_account" {
  account_id   = "${var.service_name}-worker-sa"
  display_name = "Worker Service Account for ${var.service_name}"
  project      = var.project_id
}

resource "google_project_iam_member" "worker_pubsub_subscriber" {
  project = var.project_id
  role    = "roles/pubsub.subscriber"
  member  = "serviceAccount:${google_service_account.worker_service_account.email}"
}

resource "google_project_iam_member" "worker_storage_admin" {
  project = var.project_id
  role    = "roles/storage.admin"
  member  = "serviceAccount:${google_service_account.worker_service_account.email}"
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