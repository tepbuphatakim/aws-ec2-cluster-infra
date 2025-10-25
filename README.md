# AWS EC2 Docker Swarm Cluster with Auto Scaling

This project deploys a **production-ready, highly available Nginx cluster** on AWS using **Docker Swarm** and Terraform. The infrastructure uses Docker Swarm orchestration with EC2 Auto Scaling Groups behind an Application Load Balancer for automatic scaling and high availability.

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

## Prerequisites

- AWS CLI configured with credentials (`aws configure`)
- Terraform >= 1.0 installed
- An EC2 key pair created in your AWS region
- Appropriate IAM permissions

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
key_name          = "your-key-pair-name"  # IMPORTANT: Change this!

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

