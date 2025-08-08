terraform {
  required_version = ">= 1.0"
}

# Variables
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

# Outputs
output "service_name" {
  description = "Name of the service"
  value       = var.service_name
}

output "environment" {
  description = "Environment"
  value       = var.environment
}

output "labels" {
  description = "Common labels"
  value       = local.common_labels
} 