resource "aws_lb" "this" {
  name               = "${var.name}-alb"
  load_balancer_type = "application"
  security_groups    = [var.alb_security_group_id]
  subnets            = var.public_subnet_ids

  dynamic "access_logs" {
    for_each = var.alb_logs_bucket != null ? [1] : []

    content {
      enabled = true
      bucket  = var.alb_logs_bucket
      prefix  = "${var.name}/alb"
    }
  }

  tags = {
    Name        = "${var.name}-alb"
    Environment = var.environment
  }
}

resource "aws_lb_target_group" "this" {
  name        = "${var.name}-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance"

  health_check {
    path                = "/api/health"
    matcher             = "200-399"
    interval            = 5
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name        = "${var.name}-tg"
    Environment = var.environment
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
}

# Attach Swarm Manager to Target Group
resource "aws_lb_target_group_attachment" "swarm_manager" {
  target_group_arn = aws_lb_target_group.this.arn
  target_id        = var.swarm_manager_instance_id
  port             = 80
}

resource "aws_wafv2_web_acl" "this" {
  name        = "${var.name}-waf"
  description = "WAFv2 Web ACL for ALB ${var.name}"
  scope       = "REGIONAL"

  default_action {
    allow {}
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    sampled_requests_enabled   = true
    metric_name                = "${var.name}-waf"
  }

  # AWS managed rule groups for common web exploits and bad bots
  rule {
    name     = "AWS-AWSManagedRulesCommonRuleSet"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      sampled_requests_enabled   = true
      metric_name                = "${var.name}-waf-common"
    }
  }

  rule {
    name     = "AWS-AWSManagedRulesKnownBadInputsRuleSet"
    priority = 2

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      sampled_requests_enabled   = true
      metric_name                = "${var.name}-waf-bad-inputs"
    }
  }

  rule {
    name     = "AWS-AWSManagedRulesSQLiRuleSet"
    priority = 3

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesSQLiRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      sampled_requests_enabled   = true
      metric_name                = "${var.name}-waf-sqli"
    }
  }

  rule {
    name     = "AWS-AWSManagedRulesAnonymousIpList"
    priority = 4

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesAnonymousIpList"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      sampled_requests_enabled   = true
      metric_name                = "${var.name}-waf-anon-ip"
    }
  }
}

resource "aws_wafv2_web_acl_association" "this" {
  resource_arn = aws_lb.this.arn
  web_acl_arn  = aws_wafv2_web_acl.this.arn
}

resource "aws_cloudwatch_metric_alarm" "alb_5xx_high" {
  alarm_name          = "${var.name}-alb-5xx-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  threshold           = 5
  metric_name         = "HTTPCode_ELB_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  statistic           = "Sum"
  period              = 60

  dimensions = {
    LoadBalancer = aws_lb.this.arn_suffix
  }

  alarm_description = "High number of 5xx errors on ALB – potential app issue or attack traffic"
  alarm_actions     = var.alarm_actions
}

resource "aws_cloudwatch_metric_alarm" "alb_request_count_spike" {
  alarm_name          = "${var.name}-alb-requests-spike"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  threshold           = 1000
  metric_name         = "RequestCount"
  namespace           = "AWS/ApplicationELB"
  statistic           = "Sum"
  period              = 60

  dimensions = {
    LoadBalancer = aws_lb.this.arn_suffix
  }

  alarm_description = "ALB request count spike – potential DDoS or sudden traffic surge"
  alarm_actions     = var.alarm_actions
}

