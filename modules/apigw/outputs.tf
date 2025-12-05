output "api_endpoint" {
  description = "Invoke URL of the HTTP API Gateway in front of the ALB"
  value       = aws_apigatewayv2_api.this.api_endpoint
}


