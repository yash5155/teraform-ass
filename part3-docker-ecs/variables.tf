variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = "ap-south-1"
}

variable "project_name" {
  description = "Project name used for AWS resource names"
  type        = string
  default     = "terraform-part3"
}

variable "flask_image" {
  description = "Flask backend Docker image in ECR"
  type        = string
  default     = "223532248334.dkr.ecr.ap-south-1.amazonaws.com/flask-backend:latest"
}

variable "express_image" {
  description = "Express frontend Docker image in ECR"
  type        = string
  default     = "223532248334.dkr.ecr.ap-south-1.amazonaws.com/express-frontend:latest"
}

variable "flask_container_port" {
  description = "Flask container port"
  type        = number
  default     = 5000
}

variable "express_container_port" {
  description = "Express container port"
  type        = number
  default     = 3000
}

variable "fargate_cpu" {
  description = "Fargate CPU units"
  type        = number
  default     = 256
}

variable "fargate_memory" {
  description = "Fargate memory in MB"
  type        = number
  default     = 512
}