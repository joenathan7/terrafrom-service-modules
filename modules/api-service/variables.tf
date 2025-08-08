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

variable "machine_type" {
  description = "Machine type for compute instances"
  type        = string
  default     = "e2-medium"
}

variable "instance_count" {
  description = "Number of instances in the group"
  type        = number
  default     = 2
}

variable "disk_size_gb" {
  description = "Size of the boot disk in GB"
  type        = number
  default     = 20
}

variable "subnet_cidr" {
  description = "CIDR range for the subnet"
  type        = string
  default     = "10.0.0.0/24"
} 