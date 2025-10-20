output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = module.alb.alb_dns_name
}

output "alb_url" {
  description = "URL to access the Nginx cluster"
  value       = "http://${module.alb.alb_dns_name}"
}

output "vpc_id" {
  description = "ID of the created VPC"
  value       = module.vpc.vpc_id
}

output "autoscaling_group_name" {
  description = "Name of the Auto Scaling Group"
  value       = module.ec2.autoscaling_group_name
}

output "swarm_manager_id" {
  description = "ID of the Docker Swarm Manager instance"
  value       = module.ec2.swarm_manager_id
}

output "swarm_manager_private_ip" {
  description = "Private IP of the Docker Swarm Manager"
  value       = module.ec2.swarm_manager_private_ip
}