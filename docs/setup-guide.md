# Setup Guide

This guide will help you set up the Terraform microservice modules repository and create your first microservice.

## Prerequisites

### 1. Google Cloud Platform Setup

1. **Create a GCP Project**:
   ```bash
   gcloud projects create your-project-id --name="Your Project Name"
   gcloud config set project your-project-id
   ```

2. **Enable Required APIs**:
   ```bash
   gcloud services enable compute.googleapis.com
   gcloud services enable storage.googleapis.com
   gcloud services enable cloudresourcemanager.googleapis.com
   gcloud services enable iam.googleapis.com
   gcloud services enable monitoring.googleapis.com
   gcloud services enable logging.googleapis.com
   ```

3. **Create Service Account**:
   ```bash
   gcloud iam service-accounts create terraform-sa \
     --display-name="Terraform Service Account"
   
   gcloud projects add-iam-policy-binding your-project-id \
     --member="serviceAccount:terraform-sa@your-project-id.iam.gserviceaccount.com" \
     --role="roles/editor"
   
   gcloud iam service-accounts keys create terraform-key.json \
     --iam-account=terraform-sa@your-project-id.iam.gserviceaccount.com
   ```

4. **Create Terraform State Bucket**:
   ```bash
   gsutil mb gs://terraform-state-your-project-id
   gsutil versioning set on gs://terraform-state-your-project-id
   ```

### 2. GitHub Setup

1. **Create GitHub Personal Access Token**:
   - Go to GitHub Settings > Developer settings > Personal access tokens
   - Generate a new token with `repo` and `workflow` scopes
   - Save the token securely

2. **Create Template Repositories**:
   - Create a repository named `infrastructure-template`
   - Create a repository named `service-template`
   - Set both as template repositories in GitHub settings

### 3. Repository Setup

1. **Clone this repository**:
   ```bash
   git clone https://github.com/your-org/terraform-microservice-modules.git
   cd terraform-microservice-modules
   ```

2. **Configure GitHub Secrets**:
   - Go to your repository settings > Secrets and variables > Actions
   - Add the following secrets:
     - `GCP_PROJECT_ID`: Your GCP project ID
     - `GCP_SA_KEY`: Base64-encoded service account key
     - `GITHUB_TOKEN`: Your GitHub personal access token

3. **Initialize Terraform**:
   ```bash
   cd modules/api-service
   terraform init
   ```

## Creating Your First Microservice

### Option 1: Using GitHub Actions (Recommended)

1. **Go to the Actions tab** in your repository
2. **Select "Create Microservice Instance"** workflow from the list
3. **Click "Run workflow"** and fill in the parameters:
   - Service Name: `my-first-api`
   - Service Type: `api-service`
   - Environment: `dev`
   - Project ID: `your-gcp-project-id`
   - Region: `us-central1`

### Option 2: Using Terraform CLI

1. **Create a variables file**:
   ```bash
   cat > my-service.tfvars <<EOF
   service_name = "my-first-api"
   environment  = "dev"
   project_id  = "your-gcp-project-id"
   region      = "us-central1"
   github_org  = "your-github-org"
   EOF
   ```

2. **Apply the configuration**:
   ```bash
   cd modules/api-service
   terraform plan -var-file=../../my-service.tfvars
   terraform apply -var-file=../../my-service.tfvars
   ```

## What Gets Created

When you create a microservice, the following resources are created:

### Infrastructure Resources
- **VPC Network**: Isolated network for your service
- **Subnet**: Subnet for compute instances
- **Firewall Rules**: Security rules for HTTP/HTTPS/SSH
- **Load Balancer**: Global load balancer with health checks
- **Instance Group**: Auto-scaling group of compute instances
- **Service Account**: IAM service account for the application
- **Storage Bucket**: For logs and static assets

### GitHub Repositories
- **Service Repository**: Contains your application code
- **Infrastructure Repository**: Contains infrastructure configurations

### Monitoring & Logging
- **Cloud Monitoring**: Dashboard for metrics
- **Cloud Logging**: Log aggregation and analysis
- **Health Checks**: Automated health monitoring

## Next Steps

1. **Access Your Service**:
   - Get the load balancer IP from Terraform outputs
   - Test the health endpoint: `http://<ip>/health`

2. **Develop Your Application**:
   - Clone the created service repository
   - Add your application code
   - Push changes to trigger deployment

3. **Monitor and Scale**:
   - View metrics in Google Cloud Console
   - Adjust instance count as needed
   - Set up alerts for critical metrics

## Troubleshooting

### Common Issues

1. **Permission Denied**:
   - Ensure service account has proper IAM roles
   - Check GitHub token permissions

2. **Terraform State Issues**:
   - Verify GCS bucket exists and is accessible
   - Check backend configuration

3. **Repository Creation Fails**:
   - Verify GitHub token has `repo` scope
   - Check template repositories exist

### Getting Help

- Check the logs in GitHub Actions
- Review Terraform outputs for resource information
- Consult Google Cloud Console for infrastructure details

## Security Best Practices

1. **Use Least Privilege**: Only grant necessary IAM roles
2. **Rotate Keys**: Regularly rotate service account keys
3. **Enable Audit Logs**: Monitor access to resources
4. **Network Security**: Use private subnets when possible
5. **Secret Management**: Use Google Secret Manager for sensitive data 