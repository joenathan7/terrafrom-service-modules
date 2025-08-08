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