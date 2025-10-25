#!/bin/bash
# Docker Swarm Manager Initialization Script
# This script is executed when the manager instance starts

# Update system
yum update -y

# Install Docker
yum install -y docker
systemctl start docker
systemctl enable docker
usermod -aG docker ec2-user

# Install Docker Compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose

# Install AWS CLI v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
yum install -y unzip
unzip awscliv2.zip
./aws/install

# Wait for Docker to be ready
sleep 10

# Initialize Docker Swarm
MANAGER_IP=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)
docker swarm init --advertise-addr $MANAGER_IP

# Get worker join token and save to SSM Parameter Store
WORKER_TOKEN=$(docker swarm join-token worker -q)
REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/region)
aws ssm put-parameter \
  --name "/${environment}/swarm/worker-token" \
  --value "$WORKER_TOKEN" \
  --type "String" \
  --overwrite \
  --region $REGION

# Save manager IP to SSM Parameter Store
aws ssm put-parameter \
  --name "/${environment}/swarm/manager-ip" \
  --value "$MANAGER_IP" \
  --type "String" \
  --overwrite \
  --region $REGION

# Wait a bit for workers to potentially join
sleep 30

# Create deployment directory
mkdir -p /opt/nginx-swarm
cd /opt/nginx-swarm


# Write docker-compose.yml from Terraform variable
cat > docker-compose.yml <<'EOF'
${compose_content}
EOF

# Pull nginx image
# docker pull nginx:latest

# Deploy stack using docker-compose (no build needed, using standard nginx)
docker stack deploy -c docker-compose.yml nginx-stack

# Wait for services to be deployed
sleep 10

# Show stack status
docker stack services nginx-stack
docker stack ps nginx-stack

# Log completion
echo "Docker Swarm manager initialization complete!" > /var/log/swarm-init.log
echo "Manager IP: $MANAGER_IP" >> /var/log/swarm-init.log
echo "Stack deployed: nginx-stack" >> /var/log/swarm-init.log

