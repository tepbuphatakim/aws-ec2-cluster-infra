resource "aws_apigatewayv2_api" "this" {
  name          = "${var.name}-http-api"
  protocol_type = "HTTP"

  tags = {
    Environment = var.environment
  }
}

# Proxy integration to the existing public ALB.
# This makes API Gateway sit in front of the ALB.
resource "aws_apigatewayv2_integration" "alb_proxy" {
  api_id           = aws_apigatewayv2_api.this.id
  integration_type = "HTTP_PROXY"

  integration_method     = "ANY"
  # Use HTTP because the ALB currently only has a port 80 listener.
  integration_uri        = "http://${var.alb_dns_name}/{proxy}"
  payload_format_version = "1.0"
}

resource "aws_apigatewayv2_route" "proxy" {
  api_id    = aws_apigatewayv2_api.this.id
  route_key = "ANY /{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.alb_proxy.id}"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.this.id
  name        = "$default"
  auto_deploy = true

  tags = {
    Environment = var.environment
  }
}


