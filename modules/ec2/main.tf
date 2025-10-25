# Get the latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# IAM Role for EC2 instances to access SSM Parameter Store
resource "aws_iam_role" "swarm_role" {
  name = "${var.environment}-swarm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "swarm_policy" {
  name = "${var.environment}-swarm-policy"
  role = aws_iam_role.swarm_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:PutParameter",
          "ssm:DeleteParameter"
        ]
        Resource = "arn:aws:ssm:*:*:parameter/${var.environment}/swarm/*"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "swarm_profile" {
  name = "${var.environment}-swarm-profile"
  role = aws_iam_role.swarm_role.name
}

# Docker Swarm Manager Instance
resource "aws_instance" "swarm_manager" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = var.instance_type
  key_name               = var.key_name
  subnet_id              = var.subnet_ids[0]
  vpc_security_group_ids = [var.security_group_id]
  iam_instance_profile   = aws_iam_instance_profile.swarm_profile.name

  user_data = base64encode(templatefile("${path.root}/user-data-manager.sh", {
    environment        = var.environment
    desired_capacity   = var.desired_capacity
    compose_content    = templatefile("${path.root}/docker-compose.yml.tpl", {
      desired_capacity = var.desired_capacity
    })
  }))

  tags = {
    Name        = "${var.environment}-swarm-manager"
    Environment = var.environment
    Role        = "SwarmManager"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Launch Template for Worker Nodes
resource "aws_launch_template" "swarm_worker" {
  name_prefix   = "${var.environment}-swarm-worker-"
  image_id      = data.aws_ami.amazon_linux_2.id
  instance_type = var.instance_type
  key_name      = var.key_name

  vpc_security_group_ids = [var.security_group_id]
  iam_instance_profile {
    name = aws_iam_instance_profile.swarm_profile.name
  }

  user_data = base64encode(templatefile("${path.root}/user-data-worker.sh", {
    environment = var.environment
  }))

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name        = "${var.environment}-swarm-worker"
      Environment = var.environment
      ManagedBy   = "AutoScaling"
      Role        = "SwarmWorker"
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "swarm_worker" {
  name                = "${var.environment}-swarm-worker-asg"
  vpc_zone_identifier = var.subnet_ids
  target_group_arns   = [var.target_group_arn]
  health_check_type   = "ELB"
  health_check_grace_period = 600
  
  min_size         = var.min_size
  max_size         = var.max_size
  desired_capacity = var.desired_capacity

  launch_template {
    id      = aws_launch_template.swarm_worker.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.environment}-swarm-worker"
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = var.environment
    propagate_at_launch = true
  }
}

# Auto Scaling Policy - Target Tracking (CPU)
resource "aws_autoscaling_policy" "cpu_scaling" {
  name                   = "${var.environment}-cpu-scaling-policy"
  autoscaling_group_name = aws_autoscaling_group.swarm_worker.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 70.0
  }
}

# Step Scaling Policy - Scale Down when CPU is low
resource "aws_autoscaling_policy" "scale_down" {
  name                   = "${var.environment}-scale-down-policy"
  autoscaling_group_name = aws_autoscaling_group.swarm_worker.name
  adjustment_type        = "ChangeInCapacity"
  policy_type            = "StepScaling"
  
  step_adjustment {
    scaling_adjustment          = -1
    metric_interval_upper_bound = 0
  }
}

# CloudWatch Alarm for Scale Down - triggers when CPU < 30%
resource "aws_cloudwatch_metric_alarm" "low_cpu" {
  alarm_name          = "${var.environment}-low-cpu-alarm"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 30.0
  alarm_description   = "Scale down when CPU utilization is below 30%"
  alarm_actions       = [aws_autoscaling_policy.scale_down.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.swarm_worker.name
  }
}