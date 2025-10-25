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
aws ec2 create-key-pair --key-name my-cluster-key --query 'KeyMaterial' --output text > my-cluster-key.pem

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

### 2. Update `terraform.tfvars`

Create or update `terraform.tfvars` with your values:

```hcl
aws_region         = "us-east-1"
environment        = "development"
vpc_cidr           = "10.0.0.0/16"
availability_zones = ["us-east-1a", "us-east-1b"]
instance_type      = "t2.micro"
key_name          = "my-cluster-key"  # Use the key pair name you created above (without .pem extension)

# Auto Scaling Configuration
asg_min_size         = 2
asg_max_size         = 4
asg_desired_capacity = 2
```

### 3. Initialize Terraform

```bash
terraform init
```

### 4. Review the Plan

```bash
terraform plan
```

### 5. Deploy Infrastructure

```bash
terraform apply
```

Type `yes` when prompted.

## Architecture Overview

```
Internet
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
