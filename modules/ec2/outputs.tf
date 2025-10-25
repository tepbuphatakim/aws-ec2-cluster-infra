output "autoscaling_group_id" {
  description = "ID of the Auto Scaling Group"
  value       = aws_autoscaling_group.swarm_worker.id
}

output "autoscaling_group_name" {
  description = "Name of the Auto Scaling Group"
  value       = aws_autoscaling_group.swarm_worker.name
}

output "launch_template_id" {
  description = "ID of the Launch Template"
  value       = aws_launch_template.swarm_worker.id
}

output "swarm_manager_id" {
  description = "ID of the Docker Swarm Manager instance"
  value       = aws_instance.swarm_manager.id
}

output "swarm_manager_private_ip" {
  description = "Private IP of the Docker Swarm Manager"
  value       = aws_instance.swarm_manager.private_ip
}