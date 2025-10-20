module "vpc" {
  source = "./modules/vpc"

  vpc_cidr           = var.vpc_cidr
  environment        = var.environment
  availability_zones = var.availability_zones
}

module "security" {
  source = "./modules/security"

  vpc_id      = module.vpc.vpc_id
  environment = var.environment
}

module "alb" {
  source = "./modules/alb"

  name                       = var.environment
  vpc_id                     = module.vpc.vpc_id
  public_subnet_ids          = module.vpc.public_subnet_ids
  alb_security_group_id      = module.security.alb_security_group_id
  environment                = var.environment
  swarm_manager_instance_id  = module.ec2.swarm_manager_id
}

module "ec2" {
  source = "./modules/ec2"

  instance_type      = var.instance_type
  subnet_ids         = module.vpc.public_subnet_ids
  security_group_id  = module.security.instance_security_group_id
  key_name           = var.key_name
  environment        = var.environment
  target_group_arn   = module.alb.target_group_arn
  min_size           = var.asg_min_size
  max_size           = var.asg_max_size
  desired_capacity   = var.asg_desired_capacity
}
