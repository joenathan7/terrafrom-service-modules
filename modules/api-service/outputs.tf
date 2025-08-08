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

output "vpc_name" {
  description = "Name of the VPC"
  value       = google_compute_network.vpc.name
}

output "subnet_name" {
  description = "Name of the subnet"
  value       = google_compute_subnetwork.subnet.name
}

output "backend_service_name" {
  description = "Name of the backend service"
  value       = google_compute_backend_service.api_backend.name
} 