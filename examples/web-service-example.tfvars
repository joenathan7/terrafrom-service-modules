# Example configuration for Web Service module
service_name = "frontend-app"
environment  = "staging"
project_id  = "your-gcp-project-id"
region      = "us-central1"
github_org  = "your-github-org"
domain_name = "app.yourdomain.com"

# Optional: Override default values
machine_type = "e2-standard-2"
instance_count = 2
disk_size_gb = 30
subnet_cidr = "10.0.2.0/24" 