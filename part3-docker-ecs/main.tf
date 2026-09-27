terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  required_version = ">= 1.6.0"
}

provider "aws" {
  region  = var.aws_region
  profile = "terraform"
}

# =========================================================
# VPC
# =========================================================

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

# =========================================================
# Internet Gateway
# =========================================================

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

# =========================================================
# Public Subnets
# =========================================================

resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-a"
  }
}

resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "${var.aws_region}b"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-b"
  }
}

# =========================================================
# Route Table
# =========================================================

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.project_name}-public-route-table"
  }
}

resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}

# =========================================================
# Security Group - ALB
# =========================================================

resource "aws_security_group" "alb" {
  name        = "${var.project_name}-alb-sg"
  description = "Security group for Application Load Balancer"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-alb-sg"
  }
}

# =========================================================
# Security Group - ECS
# =========================================================

resource "aws_security_group" "ecs" {
  name        = "${var.project_name}-ecs-sg"
  description = "Security group for ECS Fargate tasks"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Express traffic from ALB"
    from_port       = var.express_container_port
    to_port         = var.express_container_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  ingress {
    description     = "Flask traffic from ALB"
    from_port       = var.flask_container_port
    to_port         = var.flask_container_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  ingress {
    description = "Flask traffic from ECS tasks"
    from_port   = var.flask_container_port
    to_port     = var.flask_container_port
    protocol    = "tcp"
    self        = true
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-ecs-sg"
  }
}

# =========================================================
# CloudWatch Log Groups
# =========================================================

resource "aws_cloudwatch_log_group" "flask" {
  name              = "/ecs/${var.project_name}/flask"
  retention_in_days = 7

  tags = {
    Name = "${var.project_name}-flask-logs"
  }
}

resource "aws_cloudwatch_log_group" "express" {
  name              = "/ecs/${var.project_name}/express"
  retention_in_days = 7

  tags = {
    Name = "${var.project_name}-express-logs"
  }
}

# =========================================================
# IAM Role - ECS Task Execution
# =========================================================

resource "aws_iam_role" "ecs_task_execution" {
  name = "${var.project_name}-ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-ecs-task-execution-role"
  }
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# =========================================================
# Cloud Map Private DNS Namespace
# =========================================================

resource "aws_service_discovery_private_dns_namespace" "main" {
  name        = "terraform-part3.local"
  description = "Private DNS namespace for Part 3 ECS services"
  vpc         = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-service-discovery"
  }
}

# =========================================================
# Cloud Map - Flask Service
# =========================================================

resource "aws_service_discovery_service" "flask" {
  name = "flask"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.main.id

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {}

  tags = {
    Name = "${var.project_name}-flask-discovery"
  }
}

# =========================================================
# ECS Cluster
# =========================================================

resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name = "${var.project_name}-cluster"
  }
}

# =========================================================
# Flask Task Definition
# =========================================================

resource "aws_ecs_task_definition" "flask" {
  family                   = "${var.project_name}-flask"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]

  cpu    = var.fargate_cpu
  memory = var.fargate_memory

  execution_role_arn = aws_iam_role.ecs_task_execution.arn

  container_definitions = jsonencode([
    {
      name      = "flask"
      image     = var.flask_image
      essential = true

      portMappings = [
        {
          containerPort = var.flask_container_port
          protocol      = "tcp"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"

        options = {
          awslogs-group         = aws_cloudwatch_log_group.flask.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "flask"
        }
      }
    }
  ])

  tags = {
    Name = "${var.project_name}-flask-task"
  }
}

# =========================================================
# Express Task Definition
# =========================================================

resource "aws_ecs_task_definition" "express" {
  family                   = "${var.project_name}-express"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]

  cpu    = var.fargate_cpu
  memory = var.fargate_memory

  execution_role_arn = aws_iam_role.ecs_task_execution.arn

  container_definitions = jsonencode([
    {
      name      = "express"
      image     = var.express_image
      essential = true

      portMappings = [
        {
          containerPort = var.express_container_port
          protocol      = "tcp"
        }
      ]

      environment = [
        {
          name  = "FLASK_BACKEND_URL"
          value = "http://flask.terraform-part3.local:5000"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"

        options = {
          awslogs-group         = aws_cloudwatch_log_group.express.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "express"
        }
      }
    }
  ])

  tags = {
    Name = "${var.project_name}-express-task"
  }
}

# =========================================================
# Application Load Balancer
# =========================================================

resource "aws_lb" "main" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"

  security_groups = [
    aws_security_group.alb.id
  ]

  subnets = [
    aws_subnet.public_a.id,
    aws_subnet.public_b.id
  ]

  tags = {
    Name = "${var.project_name}-alb"
  }
}

# =========================================================
# Flask Target Group
# =========================================================

resource "aws_lb_target_group" "flask" {
  name        = "${var.project_name}-flask-tg"
  port        = var.flask_container_port
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.main.id

  health_check {
    enabled             = true
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200-399"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  tags = {
    Name = "${var.project_name}-flask-tg"
  }
}

# =========================================================
# Express Target Group
# =========================================================

resource "aws_lb_target_group" "express" {
  name        = "${var.project_name}-express-tg"
  port        = var.express_container_port
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.main.id

  health_check {
    enabled             = true
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200-399"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  tags = {
    Name = "${var.project_name}-express-tg"
  }
}

# =========================================================
# ALB Listener
# =========================================================

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.express.arn
  }
}

# =========================================================
# ALB Rule - Flask API
# =========================================================

resource "aws_lb_listener_rule" "flask" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 10

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.flask.arn
  }

  condition {
    path_pattern {
      values = [
        "/api/*"
      ]
    }
  }
}

# =========================================================
# Flask ECS Service
# =========================================================

resource "aws_ecs_service" "flask" {
  name            = "${var.project_name}-flask-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.flask.arn

  desired_count = 1
  launch_type   = "FARGATE"

  network_configuration {
    subnets = [
      aws_subnet.public_a.id,
      aws_subnet.public_b.id
    ]

    security_groups = [
      aws_security_group.ecs.id
    ]

    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.flask.arn
    container_name   = "flask"
    container_port   = var.flask_container_port
  }

  service_registries {
    registry_arn = aws_service_discovery_service.flask.arn
  }

  depends_on = [
    aws_lb_listener.http,
    aws_iam_role_policy_attachment.ecs_task_execution,
    aws_service_discovery_service.flask
  ]

  tags = {
    Name = "${var.project_name}-flask-service"
  }
}

# =========================================================
# Express ECS Service
# =========================================================

resource "aws_ecs_service" "express" {
  name            = "${var.project_name}-express-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.express.arn

  desired_count = 1
  launch_type   = "FARGATE"

  network_configuration {
    subnets = [
      aws_subnet.public_a.id,
      aws_subnet.public_b.id
    ]

    security_groups = [
      aws_security_group.ecs.id
    ]

    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.express.arn
    container_name   = "express"
    container_port   = var.express_container_port
  }

  depends_on = [
    aws_lb_listener.http,
    aws_iam_role_policy_attachment.ecs_task_execution,
    aws_ecs_service.flask
  ]

  tags = {
    Name = "${var.project_name}-express-service"
  }
}