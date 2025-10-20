variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
}

variable "environment" {
  description = "Environment name for tagging"
  type        = string
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
}
