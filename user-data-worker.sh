#!/bin/bash
# Docker Swarm Worker Initialization Script
# This script is executed when worker instances start

# Update system
yum update -y

# Install Docker
yum install -y docker
systemctl start docker
systemctl enable docker
usermod -aG docker ec2-user

# Install AWS CLI v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
yum install -y unzip
unzip awscliv2.zip
./aws/install

# Wait for Docker to be ready
sleep 10

# Get region
REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/region)

# Wait for manager to initialize and store tokens
for i in {1..30}; do
  WORKER_TOKEN=$(aws ssm get-parameter --name "/${environment}/swarm/worker-token" --region $REGION --query 'Parameter.Value' --output text 2>/dev/null)
  MANAGER_IP=$(aws ssm get-parameter --name "/${environment}/swarm/manager-ip" --region $REGION --query 'Parameter.Value' --output text 2>/dev/null)
  
  if [ ! -z "$WORKER_TOKEN" ] && [ ! -z "$MANAGER_IP" ]; then
    break
  fi
  
  echo "Waiting for swarm manager to initialize... (attempt $i/30)"
  sleep 10
done

# Join the swarm as a worker
if [ ! -z "$WORKER_TOKEN" ] && [ ! -z "$MANAGER_IP" ]; then
  docker swarm join --token $WORKER_TOKEN $MANAGER_IP:2377
  echo "Successfully joined swarm at $MANAGER_IP" > /var/log/swarm-init.log
else
  echo "Failed to retrieve swarm join information" > /var/log/swarm-init.log
  exit 1
fi

# Log completion
echo "Docker Swarm worker initialization complete!" >> /var/log/swarm-init.log
echo "Manager IP: $MANAGER_IP" >> /var/log/swarm-init.log

