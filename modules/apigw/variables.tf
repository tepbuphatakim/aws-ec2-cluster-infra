variable "name" {
  description = "Name prefix for API Gateway resources"
  type        = string
}

variable "environment" {
  description = "Environment name for tagging"
  type        = string
}

variable "alb_dns_name" {
  description = "DNS name of the upstream Application Load Balancer"
  type        = string
}


