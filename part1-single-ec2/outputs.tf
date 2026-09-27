output "ec2_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.app.public_ip
}

output "flask_url" {
  description = "Flask application URL"
  value       = "http://${aws_instance.app.public_ip}:5000"
}

output "express_url" {
  description = "Express application URL"
  value       = "http://${aws_instance.app.public_ip}:3000"
}

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "ec2_instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.app.id
}