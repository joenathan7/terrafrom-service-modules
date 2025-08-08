# Terraform Microservice Modules Repository

This repository contains custom Terraform modules for microservice definitions. Each microservice definition includes infrastructure automation that creates two GitHub repositories when a new instance is deployed.

## Repository Structure

```
├── modules/                    # Terraform modules for different microservice types
│   ├── api-service/           # API service module
│   ├── web-service/           # Web service module
│   └── worker-service/        # Background worker service module
├── templates/                  # GitHub repository templates
│   ├── infrastructure-template/ # Template for infrastructure repositories
│   └── service-template/       # Template for service repositories
├── .github/workflows/          # GitHub Actions workflows
│   ├── create-microservice.yml # Workflow to create new microservice instances
│   └── terraform-apply.yml    # Workflow to apply Terraform changes
├── examples/                   # Example configurations
└── docs/                      # Documentation
```

## How It Works

1. **Microservice Definition**: Each module defines a microservice type with its infrastructure requirements
2. **GitHub Actions**: When a new microservice instance is created, GitHub Actions automatically:
   - Creates two new repositories (service + infrastructure)
   - Applies Terraform configuration
   - Sets up CI/CD pipelines
3. **Template Repositories**: Uses GitHub repository templates for consistent structure

## Quick Start

### Creating a New Microservice Instance

1. Go to the Actions tab in your GitHub repository
2. Select the "Create Microservice Instance" workflow
3. Click "Run workflow" and configure the microservice parameters:
   - **Service Name**: Name for your microservice (e.g., `my-api-service`)
   - **Service Type**: Choose from `api-service`, `web-service`, or `worker-service`
   - **Environment**: Choose from `dev`, `staging`, or `production`
   - **Domain Name**: (Optional) Domain name for web services

### Available Modules

- **api-service**: REST API services with GitHub repository creation
- **web-service**: Web applications with domain support and GitHub repository creation
- **worker-service**: Background processing services with message queue support and GitHub repository creation

## Prerequisites

- Terraform >= 1.0
- GitHub account with repository creation permissions
- GitHub Personal Access Token with repo scope

## Contributing

1. Fork this repository
2. Create a feature branch
3. Add your module or improvements
4. Submit a pull request

## License

MIT License - see LICENSE file for details 