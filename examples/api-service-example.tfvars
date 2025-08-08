# Example configuration for API Service module
service_name = "user-api"
environment  = "production"
project_id  = "your-gcp-project-id"
region      = "us-central1"
github_org  = "your-github-org"

# Optional: Override default values
machine_type = "e2-standard-2"
instance_count = 3
disk_size_gb = 50
subnet_cidr = "10.0.1.0/24" 