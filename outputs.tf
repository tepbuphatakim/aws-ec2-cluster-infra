output "alb_url" {
  description = "URL to access the Nginx cluster"
  value       = "http://${module.alb.alb_dns_name}"
}
