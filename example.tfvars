# Example terraform.tfvars
# Copy this file to terraform.tfvars and customize the values

# AWS Configuration
aws_region = "us-east-1"
environment = "development"

# Network Configuration
vpc_cidr = "10.0.0.0/16"
availability_zones = ["us-east-1a", "us-east-1b"]

# EC2 Configuration
instance_type = "t2.micro"
key_name = "your-key-pair-name"  # CHANGE THIS!

# Auto Scaling Configuration
asg_min_size = 2
asg_max_size = 4
asg_desired_capacity = 2

