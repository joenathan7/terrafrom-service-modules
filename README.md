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
   ```yaml
   - name: Create Microservice
     uses: ./.github/actions/create-microservice
     with:
       service-name: my-api-service
       service-type: api-service
       environment: production
   ```

### Available Modules

- **api-service**: REST API services with load balancers and auto-scaling
- **web-service**: Web applications with CDN and SSL certificates
- **worker-service**: Background processing services with message queues

## Prerequisites

- Terraform >= 1.0
- Google Cloud Platform account
- GitHub account with repository creation permissions
- GitHub Personal Access Token with repo scope

## Contributing

1. Fork this repository
2. Create a feature branch
3. Add your module or improvements
4. Submit a pull request

## License

MIT License - see LICENSE file for details 