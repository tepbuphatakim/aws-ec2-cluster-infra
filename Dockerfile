FROM nginx:latest

# Install curl for accessing EC2 metadata
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

# Copy custom entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Set custom entrypoint
ENTRYPOINT ["/entrypoint.sh"]

# Default command
CMD ["nginx", "-g", "daemon off;"]

