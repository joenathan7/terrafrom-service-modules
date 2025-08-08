terraform {
  required_version = ">= 1.0"
  required_providers {
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

output "service_name" {
  description = "Name of the service"
  value       = var.service_name
}

output "environment" {
  description = "Environment"
  value       = var.environment
} 