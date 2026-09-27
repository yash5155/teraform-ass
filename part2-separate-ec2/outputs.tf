# ============================================================
# Flask EC2 Outputs
# ============================================================

output "flask_instance_id" {
  description = "Flask EC2 instance ID"
  value       = aws_instance.flask.id
}

output "flask_public_ip" {
  description = "Public IP address of Flask EC2"
  value       = aws_instance.flask.public_ip
}

output "flask_private_ip" {
  description = "Private IP address of Flask EC2"
  value       = aws_instance.flask.private_ip
}

output "flask_url" {
  description = "Flask backend URL"
  value       = "http://${aws_instance.flask.public_ip}:5000"
}


# ============================================================
# Express EC2 Outputs
# ============================================================

output "express_instance_id" {
  description = "Express EC2 instance ID"
  value       = aws_instance.express.id
}

output "express_public_ip" {
  description = "Public IP address of Express EC2"
  value       = aws_instance.express.public_ip
}

output "express_private_ip" {
  description = "Private IP address of Express EC2"
  value       = aws_instance.express.private_ip
}

output "express_url" {
  description = "Express frontend URL"
  value       = "http://${aws_instance.express.public_ip}:3000"
}


# ============================================================
# VPC Output
# ============================================================

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}