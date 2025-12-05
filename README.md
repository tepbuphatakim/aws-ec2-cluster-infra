# AWS EC2 Docker Swarm Cluster with Auto Scaling

## Prerequisites

- AWS CLI configured with credentials (`aws configure`)
- Terraform >= 1.0 installed
- An EC2 key pair created in your AWS region (see instructions below)
- Appropriate IAM permissions

### Creating an EC2 Key Pair

You need an EC2 key pair to SSH into your instances. Create one using either method:

**Option 1: Using AWS CLI**
```bash
# Create a new key pair and save it locally
aws ec2 create-key-pair --key-name my-cluster-key --region ap-southeast-1 --query 'KeyMaterial' --output text > my-cluster-key.pem

# Set appropriate permissions (Linux/Mac)
chmod 400 my-cluster-key.pem

# On Windows (PowerShell)
icacls my-cluster-key.pem /inheritance:r /grant:r "$($env:USERNAME):(R)"
```

## Quick Start

### 1. Clone and Configure

```bash
cd aws-ec2-cluster-infra
```

### 2. Choose an environment (UAT / PROD)

This repo is set up to deploy the **same infra** into separate environments using:

- **Terraform workspaces** for separate state (`uat`, `prod`)
- **Per-environment tfvars files**: `uat.tfvars`, `prod.tfvars`

You can still use `terraform.tfvars` for a local/dev environment if you want, but for UAT/PROD use the files below.

#### UAT configuration (`uat.tfvars`)

```hcl
aws_region         = "ap-southeast-1"
environment        = "uat"
vpc_cidr           = "10.0.0.0/16"
availability_zones = ["ap-southeast-1a", "ap-southeast-1b"]
instance_type      = "t2.micro"
key_name           = "my-cluster-key-3"

# Auto Scaling Configuration
asg_min_size         = 2
asg_max_size         = 4
asg_desired_capacity = 2
```

#### PROD configuration (`prod.tfvars`)

```hcl
aws_region         = "ap-southeast-1"
environment        = "prod"
vpc_cidr           = "10.1.0.0/16"
availability_zones = ["ap-southeast-1a", "ap-southeast-1b"]
instance_type      = "t2.micro"
key_name           = "my-cluster-key-3"

# Auto Scaling Configuration
asg_min_size         = 2
asg_max_size         = 4
asg_desired_capacity = 2
```

> Make sure `key_name` matches an existing EC2 key pair in `ap-southeast-1`.

### 3. Initialize Terraform

```bash
terraform init
```

### 4. Select environment and review the plan

#### UAT

```bash
terraform workspace new uat      # first time only
terraform workspace select uat
terraform plan -var-file=uat.tfvars
```

#### PROD

```bash
terraform workspace new prod     # first time only
terraform workspace select prod
terraform plan -var-file=prod.tfvars
```

```bash
terraform plan
```

### 5. Deploy Infrastructure

#### Deploy to UAT

```bash
terraform workspace select uat
terraform apply -var-file=uat.tfvars
```

#### Deploy to PROD

```bash
terraform workspace select prod
terraform apply -var-file=prod.tfvars
```

Type `yes` when prompted.

## Architecture Overview

```
Internet
    ↓
Amazon API Gateway (HTTP API)
    ↓
Application Load Balancer (ALB)
    ↓
Target Group
    ↓
Docker Swarm Cluster
    ├── Manager Node (EC2)
    └── Worker Nodes (Auto Scaling Group 2-4 instances)
        ↓
Docker Swarm Service (Nginx)
    ↓
Spread across multiple Availability Zones
```

The **primary public entry point** for your applications is now **API Gateway**, which proxies
all incoming HTTP requests to the **ALB**, and then to the Docker Swarm cluster. You can still
access the ALB URL directly (for troubleshooting or internal use), but for external clients
you should use the `api_gateway_url` output.

