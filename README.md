# AWS EC2 Docker Swarm Cluster with Nginx

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

## Project Structure

```
.
├── modules/
│   ├── vpc/                # VPC, subnets, internet gateway, route tables
│   ├── security/           # Security groups for ALB and EC2 instances (includes Swarm ports)
│   ├── alb/                # Application Load Balancer, target group, listener
│   └── ec2/                # Swarm manager, worker nodes, Auto Scaling Group, scaling policies
├── main.tf                 # Root module configuration
├── variables.tf            # Input variables
├── outputs.tf              # Output values (ALB DNS, Swarm manager IP, etc.)
├── providers.tf            # AWS provider configuration
├── terraform.tfvars        # Variable values (customize this)
├── docker-compose.yml      # Docker stack configuration (static, for reference)
├── docker-compose.yml.tpl  # Docker stack template (used by Terraform)
├── Dockerfile              # Custom Nginx image definition
├── entrypoint.sh           # Custom entrypoint for hostname display
├── user-data-manager.sh    # Swarm manager initialization script template
├── user-data-worker.sh     # Swarm worker initialization script template
└── DOCKER-SWARM-COMMANDS.md # Docker Swarm command reference
```

### How Files Are Used

**Terraform reads from your project root:**
- `Dockerfile` → Embedded into manager user_data
- `entrypoint.sh` → Embedded into manager user_data
- `docker-compose.yml.tpl` → Rendered with variables and embedded into manager user_data
- `user-data-manager.sh` → Template for manager instance initialization
- `user-data-worker.sh` → Template for worker instance initialization

**When you run `terraform apply`:**
1. Terraform reads all files from the project root
2. Renders templates with your variables (e.g., `desired_capacity`)
3. Embeds them into EC2 user_data
4. EC2 instances use the embedded scripts on startup

**To update docker-compose.yml:**
1. Edit `docker-compose.yml.tpl` in your project root
2. Run `terraform apply` to update the manager instance
3. Or SSH to manager and manually update `/opt/nginx-swarm/docker-compose.yml`


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

### 6. Access Your Nginx Cluster

After deployment completes (3-5 minutes), Terraform will output the ALB DNS:

```bash
terraform output alb_url
```

Open the URL in your browser:
```
http://development-alb-123456789.us-east-1.elb.amazonaws.com
```

You should see the Nginx welcome page with the hostname and instance ID!

## Scaling Behavior

The Auto Scaling Group will:
- **Scale OUT**: Add instances when average CPU > 70%
- **Scale IN**: Remove instances when average CPU < 70%
- **Min instances**: 2 (always running)
- **Max instances**: 4 (limit)
- **Health checks**: Instances failing health checks are automatically replaced

## Customization

### Change Instance Type

Edit `terraform.tfvars`:
```hcl
instance_type = "t3.small"  # Or t3.medium, t3.large, etc.
```

### Adjust Scaling Limits

Edit `terraform.tfvars`:
```hcl
asg_min_size         = 3  # Minimum instances
asg_max_size         = 6  # Maximum instances
asg_desired_capacity = 3  # Starting capacity
```

### Change AWS Region

Edit `terraform.tfvars`:
```hcl
aws_region         = "us-west-2"
availability_zones = ["us-west-2a", "us-west-2b"]
```

### Customize Nginx Container

**Option 1: Edit files in project root (Recommended)**
1. Modify files in your project root:
   - `Dockerfile` - Change the base image or add packages
   - `entrypoint.sh` - Customize the HTML or startup behavior
   - `docker-compose.yml.tpl` - Update service configuration
2. Run `terraform apply` to deploy changes (will replace manager instance)

**Option 2: Quick changes on manager (for testing)**
1. SSH to manager node: `ssh -i ~/.ssh/your-key.pem ec2-user@<manager-ip>`
2. Edit files in `/opt/nginx-swarm/`:
   ```bash
   cd /opt/nginx-swarm
   vi docker-compose.yml  # or Dockerfile, entrypoint.sh
   ```
3. Rebuild and redeploy:
   ```bash
   docker build -t nginx-custom:latest .
   docker stack deploy -c docker-compose.yml nginx-stack
   ```
4. **Note**: Changes will be lost if manager is replaced!

**Option 3: Modify service directly (runtime changes)**
```bash
# Scale replicas
docker service scale nginx-stack_nginx=5

# Update image
docker service update --image nginx:alpine nginx-stack_nginx

# Add environment variable
docker service update --env-add NEW_VAR=value nginx-stack_nginx

# Update resource limits
docker service update --limit-cpu 0.5 --limit-memory 512M nginx-stack_nginx
```

**Example: Change replicas count**
1. Edit `docker-compose.yml.tpl` line 9: `replicas: ${desired_capacity}`
2. Or change in `terraform.tfvars`: `asg_desired_capacity = 5`
3. Run `terraform apply`

## Monitoring

### View Auto Scaling Activity

```bash
aws autoscaling describe-scaling-activities \
  --auto-scaling-group-name development-nginx-asg \
  --max-records 10
```

### Check Instance Health

```bash
aws elbv2 describe-target-health \
  --target-group-arn $(terraform output -raw target_group_arn)
```

### View ALB Metrics in AWS Console

Navigate to: **EC2 → Load Balancers → Select your ALB → Monitoring**

## Docker Swarm Management

### Get Swarm Manager IP

```bash
terraform output swarm_manager_private_ip
```

### SSH to Swarm Manager

```bash
# Get manager public IP from AWS Console or:
aws ec2 describe-instances \
  --filters "Name=tag:Role,Values=SwarmManager" "Name=tag:Environment,Values=development" \
  --query "Reservations[].Instances[].PublicIpAddress" \
  --output text

ssh -i ~/.ssh/your-key.pem ec2-user@<manager-ip>
```

### Manage Docker Swarm (on Manager Node)

```bash
# View swarm nodes
docker node ls

# View deployed stacks
docker stack ls

# View services in the nginx-stack
docker stack services nginx-stack

# View service tasks (containers)
docker stack ps nginx-stack

# Scale the service
docker service scale nginx-stack_nginx=5

# Update the service
docker service update nginx-stack_nginx

# Remove the stack
docker stack rm nginx-stack

# Redeploy after changes
cd /opt/nginx-swarm
docker stack deploy -c docker-compose.yml nginx-stack
```

### View Service Logs

```bash
# View logs from all replicas
docker service logs nginx-stack_nginx

# Follow logs
docker service logs -f nginx-stack_nginx

# View logs from specific replica
docker logs <container-id>
```

## SSH Access to Worker Instances

Find worker instance IPs:
```bash
aws ec2 describe-instances \
  --filters "Name=tag:Role,Values=SwarmWorker" "Name=tag:Environment,Values=development" \
  --query "Reservations[].Instances[].PublicIpAddress" \
  --output text
```

SSH into a worker:
```bash
ssh -i ~/.ssh/your-key.pem ec2-user@<worker-ip>
```

Check Docker status on worker:
```bash
# View running containers
docker ps

# Check node status
docker info | grep Swarm

# View node tasks
docker node ps $(docker info --format '{{.Swarm.NodeID}}')
```

## Cost Estimate

With default settings (1 manager + 2 worker t2.micro instances, ALB):
- **EC2 Instances**: ~$22/month (3 × t2.micro: 1 manager + 2 workers)
- **Application Load Balancer**: ~$20/month
- **Data Transfer**: Variable
- **SSM Parameter Store**: Free (< 10k parameters)
- **Total**: ~$42-47/month

💡 **Cost Savings**: Use `t3.micro` for better performance at similar cost, or stop/destroy when not in use.

## Outputs

After deployment, these values are available:

```bash
terraform output alb_dns_name              # ALB DNS name
terraform output alb_url                   # Full HTTP URL
terraform output vpc_id                    # VPC ID
terraform output autoscaling_group_name    # ASG name
terraform output swarm_manager_id          # Swarm manager instance ID
terraform output swarm_manager_private_ip  # Swarm manager private IP
```

## Cleanup

To destroy all resources:

```bash
terraform destroy
```

Type `yes` when prompted. This will:
1. Terminate all EC2 instances
2. Delete the Auto Scaling Group
3. Delete the Application Load Balancer
4. Remove security groups, subnets, and VPC

## Troubleshooting

### Issue: Can't access ALB URL
- **Wait 3-5 minutes** for swarm cluster to initialize and services to deploy
- Check security groups allow port 80
- Verify instances are running: `aws autoscaling describe-auto-scaling-groups`
- Check swarm service status: SSH to manager and run `docker stack ps nginx-stack`

### Issue: Worker nodes not joining swarm
- **Check SSM Parameter Store**: Verify tokens exist in Parameter Store
- **IAM permissions**: Ensure EC2 instances have IAM role to access SSM
- **View worker logs**: `cat /var/log/cloud-init-output.log` on worker node
- **Manually check token**: On manager, run `docker swarm join-token worker`

### Issue: Swarm service not deploying
- SSH to manager node
- Check stack status: `docker stack ps nginx-stack`
- View service logs: `docker service logs nginx-stack_nginx`
- Check if custom image built: `docker images | grep nginx-custom`
- Rebuild and redeploy:
  ```bash
  cd /opt/nginx-swarm
  docker build -t nginx-custom:latest .
  docker stack deploy -c docker-compose.yml nginx-stack
  ```

### Issue: Instances failing health checks
- SSH to manager/worker and check Docker: `docker ps`
- View swarm service logs: `docker service logs nginx-stack_nginx`
- Check user data execution: `cat /var/log/cloud-init-output.log`
- Verify overlay network: `docker network ls`

### Issue: Auto Scaling not working
- Check CloudWatch metrics for the ASG
- Review scaling policies: `aws autoscaling describe-policies`
- Verify IAM permissions for Auto Scaling
- Note: New worker nodes will auto-join swarm but service replicas won't auto-scale (manual: `docker service scale`)

### Issue: Service shows fewer replicas than expected
- Check node availability: `docker node ls` (on manager)
- View service state: `docker service ps nginx-stack_nginx`
- Check for failed tasks: Look for "Failed" or "Rejected" states
- Verify resources: Ensure nodes have enough CPU/memory

## Best Practices Implemented

✅ Multi-AZ deployment for high availability  
✅ Docker Swarm orchestration for container management  
✅ Security groups with least privilege access  
✅ Swarm ports properly configured for cluster communication  
✅ ALB health checks with automatic instance replacement  
✅ Auto Scaling based on metrics  
✅ Infrastructure as Code with Terraform  
✅ Modular architecture for reusability  
✅ Docker Compose for service definition  
✅ IAM roles for secure SSM Parameter Store access  
✅ Tagged resources for cost tracking  
✅ Launch templates for version control  
✅ Overlay networking for container communication  

## Future Enhancements

- [ ] Add HTTPS support with ACM certificate
- [ ] Implement blue-green deployments with Swarm
- [ ] Add CloudWatch alarms and SNS notifications
- [ ] Set up Docker registry (ECR) for image management
- [ ] Implement Swarm secrets for sensitive data
- [ ] Add WAF for additional security
- [ ] Implement private subnets with NAT gateway
- [ ] Add RDS database backend with Swarm service
- [ ] Implement CI/CD pipeline for stack updates
- [ ] Add monitoring with Prometheus/Grafana stack
- [ ] Implement log aggregation (ELK/CloudWatch)
- [ ] Add multiple Swarm managers for HA (3 or 5 managers)
- [ ] Implement service mesh (Traefik) for advanced routing

## License

This project is open source and available for educational purposes.

## Support

For issues or questions:
1. Check AWS Console for resource status
2. Review CloudWatch logs
3. Verify Terraform state: `terraform state list`
