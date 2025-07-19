# Shortlink Infrastructure

This repository contains Terraform configurations for deploying a production-ready infrastructure on AWS to host CapRover and GitLab. The setup includes a VPC, Application Load Balancer (ALB), EC2 instances, Elastic Container Registry (ECR) repositories, and a Web Application Firewall (WAF) to secure the application. The infrastructure is deployed in the `eu-north-1` region and uses a remote Terraform state stored in S3 with DynamoDB locking.

## Overview

The infrastructure is designed to:

- Host CapRover for containerized application deployment.
- Run GitLab for source code management and CI/CD.
- Use an ALB to route traffic to CapRover and GitLab instances.
- Secure traffic with a WAF, including IP whitelisting and rate limiting.
- Store container images in ECR for application deployments.

### Components

- **VPC**: A single VPC with public and private subnets for network isolation.
- **ALB**: Routes HTTP/HTTPS traffic to CapRover and GitLab instances via target groups.
- **EC2 Instances**: Hosts CapRover (`prod-caprover`) and GitLab (`prod-gitlab`).
- **ECR Repositories**: Stores Docker images for `shortlink-frontend`, `shortlink-backend-go`, and `shortlink-backend-py`.
- **WAF**: Protects the ALB with managed rules, IP whitelisting, and rate limiting.
- **Terraform State**: Stored in an S3 bucket (`terraform-state-bucket-caprover`) with DynamoDB locking (`terraform-lock-table`).

## Prerequisites

Before you start, ensure you have:

- **AWS CLI** installed and configured with credentials (`aws configure`).
- **Terraform** (version &gt;= 1.5.7) installed. Use `tfenv` to manage versions:

  ```bash
  tfenv install 1.5.7
  tfenv use 1.5.7
  ```
- **jq** installed for scripts (e.g., `sudo apt-get install jq` on Ubuntu).
- **GitHub repository** with Actions enabled.
- **AWS IAM permissions** for EC2, ELBv2, ECR, WAFv2, S3, and DynamoDB (see IAM Policy).
- A **GitHub Personal Access Token** or AWS credentials stored as GitHub Secrets.

## Getting Started

### 1. Clone the Repository

```bash
git clone <repository-url>
cd <repository-directory>
```

### 2. Configure Variables

Define variables in a `terraform.tfvars` file or pass them via the CLI. Example `terraform.tfvars`:

```hcl
env         = "prod"
allowed_ips = ["203.0.113.0/24"] # Replace with your whitelisted IPs
alb_arn     = "" # Populated by ALB module output
```

- `env`: Environment name (e.g., `prod`, `dev`).
- `allowed_ips`: IPs allowed by the WAF (CIDR notation).
- `alb_arn`: Set by the ALB module; leave empty if using module outputs.

### 3. Initialize Terraform

Set up the Terraform backend and download providers:

```bash
terraform init -backend-config=backend.hcl
```

The `backend.hcl` file configures the S3 backend:

```hcl
bucket         = "terraform-state-bucket-caprover"
key            = "shortlink-app/terraform.tfstate"
region         = "eu-north-1"
dynamodb_table = "terraform-lock-table"
encrypt        = true
```

Ensure the DynamoDB table `terraform-lock-table` exists:

```bash
aws dynamodb describe-table --table-name terraform-lock-table --region eu-north-1
```

If it doesn’t, create it:

```bash
aws dynamodb create-table \
  --table-name terraform-lock-table \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
  --region eu-north-1
```

### 4. Validate Configuration

Check formatting and validate the configuration:

```bash
terraform fmt -check
terraform validate
```

If `fmt` fails, run `terraform fmt` to fix formatting. If `validate` fails, check for missing variables or module references.

### 5. Plan the Deployment

Generate a plan to review resources:

```bash
terraform plan -out=tfplan
```

Verify the plan includes:

- One VPC (`prod-vpc`).
- ALB (`prod-shortlink-alb`) and target groups.
- EC2 instances (`prod-caprover`, `prod-gitlab`).
- ECR repositories (`shortlink-frontend`, `shortlink-backend-go`, `shortlink-backend-py`).
- WAF Web ACL (`prod-waf-acl`) and IP Set (`prod-whitelist`).

### 6. Deploy with GitHub Actions

This repository uses a GitHub Actions workflow (`.github/workflows/terraform.yml`) to deploy the infrastructure automatically on push to the `main` branch.

#### Set Up GitHub Secrets

1. Go to your GitHub repository &gt; Settings &gt; Secrets and variables &gt; Actions.
2. Add:
   - `AWS_ACCESS_KEY_ID`: Your AWS access key.
   - `AWS_SECRET_ACCESS_KEY`: Your AWS secret key.

#### IAM Policy

Ensure your AWS credentials have permissions:

```json
{
  "Effect": "Allow",
  "Action": [
    "ec2:*",
    "elasticloadbalancing:*",
    "ecr:*",
    "wafv2:*",
    "s3:*",
    "dynamodb:*"
  ],
  "Resource": "*"
}
```

#### Push Changes

Commit and push your changes:

```bash
git add .
git commit -m "Update Terraform configuration"
git push origin main
```

#### Monitor Deployment

- Go to GitHub &gt; Actions tab.
- Check the workflow run for errors. Logs will show `terraform init`, `validate`, `plan`, and `apply` steps.
- If it fails, review the logs and update the configuration.

### 7. Verify Deployment

After the GitHub Actions workflow completes, verify resources:

```bash
aws ec2 describe-vpcs --region eu-north-1
aws elbv2 describe-load-balancers --region eu-north-1
aws ec2 describe-instances --region eu-north-1
aws ecr describe-repositories --region eu-north-1
aws wafv2 list-web-acls --scope REGIONAL --region eu-north-1
aws wafv2 list-ip-sets --scope REGIONAL --region eu-north-1
```

- Access the ALB DNS name to test CapRover and GitLab.

## Troubleshooting

- **Duplicate VPCs**: Ensure the VPC module creates only one VPC. Check `modules/vpc/main.tf` for duplicate resources.
- **WAF Errors**: Verify `allowed_ips` is set correctly. If the IP Set blocks all traffic, update the WAF rules in `modules/waf/main.tf`.
- **State Mismatches**: Do not delete `.terraform` or `.terraform.lock.hcl`. Use `terraform import` to sync existing resources.
- **GitHub Actions Failures**: Check logs for permission issues or missing variables. Ensure AWS credentials are valid.

## Best Practices

- **Preserve Terraform Files**: Commit `.terraform.lock.hcl` to Git to lock provider versions:

  ```bash
  git add .terraform.lock.hcl
  git commit -m "Add Terraform lock file"
  ```
- **Environment-Specific States**: Use unique state keys:

  ```hcl
  key = "shortlink-app/${var.env}/terraform.tfstate"
  ```
- **Backup State**: Regularly back up the state file:

  ```bash
  aws s3 cp s3://terraform-state-bucket-caprover/shortlink-app/terraform.tfstate s3://terraform-state-bucket-caprover/shortlink-app/terraform.tfstate.backup
  ```

## Contributing

- Submit pull requests for changes.
- Test configurations locally with `terraform plan` before pushing.
- Update this README for new features or modules.

## License

MIT License. See LICENSE for details.
