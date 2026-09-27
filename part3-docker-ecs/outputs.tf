output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = aws_ecs_cluster.main.name
}

output "flask_service_name" {
  description = "Flask ECS service name"
  value       = aws_ecs_service.flask.name
}

output "express_service_name" {
  description = "Express ECS service name"
  value       = aws_ecs_service.express.name
}

output "flask_ecr_image" {
  description = "Flask ECR image"
  value       = var.flask_image
}

output "express_ecr_image" {
  description = "Express ECR image"
  value       = var.express_image
}

output "alb_dns_name" {
  description = "Application Load Balancer DNS name"
  value       = aws_lb.main.dns_name
}

output "application_url" {
  description = "Public application URL"
  value       = "http://${aws_lb.main.dns_name}"
}

output "flask_api_url" {
  description = "Flask API URL through ALB"
  value       = "http://${aws_lb.main.dns_name}/api"
}