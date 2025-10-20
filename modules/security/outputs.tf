output "alb_security_group_id" {
  description = "ID of the ALB security group"
  value       = aws_security_group.alb_sg.id
}

output "instance_security_group_id" {
  description = "ID of the instance security group"
  value       = aws_security_group.instance_sg.id
}
