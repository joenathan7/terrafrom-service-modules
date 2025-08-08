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