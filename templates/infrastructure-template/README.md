# Infrastructure Template Repository

This is a template repository for microservice infrastructure. It contains example Terraform configurations for creating GCP resources.

## Repository Structure

```
├── terraform/              # Terraform configurations
│   ├── main.tf            # Main Terraform configuration
│   ├── variables.tf       # Variable definitions
│   ├── outputs.tf         # Output definitions
│   └── providers.tf       # Provider configurations
├── scripts/               # Helper scripts
│   ├── deploy.sh         # Deployment script
│   └── destroy.sh        # Cleanup script
├── docs/                 # Documentation
└── .github/             # GitHub Actions workflows
    └── workflows/
        └── deploy.yml    # Deployment workflow
```

## Quick Start

1. **Clone this repository** (it will be created automatically when a new microservice is deployed)
2. **Configure variables** in `terraform/variables.tf`
3. **Run deployment**:
   ```bash
   cd terraform
   terraform init
   terraform plan
   terraform apply
   ```

## Available Resources

This template includes configurations for:

- **Compute Engine**: Virtual machines and instance groups
- **Load Balancing**: HTTP/HTTPS load balancers
- **Networking**: VPC, subnets, and firewall rules
- **Storage**: Cloud Storage buckets
- **Monitoring**: Cloud Monitoring and logging
- **Security**: IAM roles and service accounts

## Environment Variables

Set the following environment variables:

- `GCP_PROJECT_ID`: Your Google Cloud Project ID
- `GCP_SA_KEY`: Base64-encoded service account key

## Contributing

1. Make changes to the Terraform configurations
2. Test with `terraform plan`
3. Submit a pull request
4. Merge to trigger automatic deployment

## License

MIT License - see LICENSE file for details 