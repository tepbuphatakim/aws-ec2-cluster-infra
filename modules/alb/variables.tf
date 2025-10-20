variable "name" {
  description = "Name prefix for ALB resources"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs for the ALB"
  type        = list(string)
}

variable "alb_security_group_id" {
  description = "Security group ID for the ALB"
  type        = string
}

variable "environment" {
  description = "Environment name for tagging"
  type        = string
}

variable "swarm_manager_instance_id" {
  description = "ID of the Swarm Manager instance to attach to target group"
  type        = string
}

