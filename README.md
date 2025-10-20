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

## Key Features

✅ **Docker Swarm Orchestration**: Containerized services managed by Swarm  
✅ **High Availability**: Multi-AZ deployment with Auto Scaling  
✅ **Auto Scaling**: Automatically scales based on CPU utilization (70% threshold)  
✅ **Load Balancing**: Application Load Balancer distributes traffic  
✅ **Docker Compose**: Services defined using docker-compose.yml  
✅ **Service Discovery**: Built-in Swarm service discovery and networking  
✅ **Health Checks**: ALB and Swarm perform health checks on services  
✅ **Infrastructure as Code**: Fully automated with Terraform  
✅ **Modular Design**: Organized in reusable modules  


## Components

### 1. VPC Module
- Creates VPC with custom CIDR block
- Multiple public subnets across different AZs
- Internet Gateway for public internet access
- Route tables for traffic routing

### 2. Security Module
- **ALB Security Group**: Allows HTTP (80) and HTTPS (443) from internet
- **Instance Security Group**: 
  - Allows HTTP from ALB only
  - SSH for admin access
  - Docker Swarm ports for cluster communication:
    - 2377/tcp: Cluster management
    - 7946/tcp & udp: Node communication
    - 4789/udp: Overlay network traffic

### 3. ALB Module
- Application Load Balancer in public subnets
- Target Group for health checking instances
- HTTP listener forwarding traffic to target group
- Health checks every 30 seconds

### 4. EC2 Module (Docker Swarm)
- **Swarm Manager Node**: Dedicated EC2 instance that:
  - Initializes Docker Swarm cluster
  - Stores join tokens in AWS Systems Manager Parameter Store
  - Deploys nginx service using docker-compose.yml (docker stack deploy)
  - Manages service replicas and orchestration
  
- **Worker Nodes (Auto Scaling Group)**: Instances that:
  - Automatically join the Swarm cluster
  - Retrieve join tokens from SSM Parameter Store
  - Run Swarm service containers
  - Scale from 2-4 instances based on CPU
  
- **Custom Nginx Image**: Built with:
  - Entrypoint script that displays hostname and instance ID
  - Based on official nginx:latest image
  - Automatically deployed as a Swarm service

- **Service Configuration**:
  - Replicas: Match ASG desired capacity
  - Update strategy: Rolling updates (1 at a time, 10s delay)
  - Network: Overlay network for inter-container communication
  - Placement: Max 1 replica per node

- **IAM Integration**: EC2 instances have IAM role to access SSM Parameter Store

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

