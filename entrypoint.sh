#!/bin/bash

# Fetch instance ID from EC2 metadata
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)

# Create custom HTML page with hostname and instance ID
echo '<h1>Nginx Server: '$(hostname)'</h1><p>Instance ID: '$INSTANCE_ID'</p>' > /usr/share/nginx/html/index.html

# Execute the main nginx command
exec "$@"

