# Security group for Load Balancer
resource "aws_security_group" "lb" {
  name        = "${var.environment}-lb-sg"
  description = "Security group for Load Balancer"
  vpc_id      = var.vpc_id
  
  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    description = "HTTPS from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = merge(var.tags, {
    Name = "${var.environment}-lb-sg"
  })
}

# Classic Load Balancer
resource "aws_elb" "main" {
  name = "${var.environment}-digit-lb"
  
  subnets         = var.public_subnet_ids
  security_groups = [aws_security_group.lb.id]
  internal        = var.internal
  
  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }
  
  listener {
    instance_port      = 443
    instance_protocol  = "https"
    lb_port            = 443
    lb_protocol        = "https"
    ssl_certificate_id = var.ssl_certificate_id
  }
  
  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    target              = "HTTP:80/health"
    interval            = 30
  }
  
  idle_timeout = var.idle_timeout
  
  cross_zone_load_balancing   = var.cross_zone_load_balancing
  connection_draining         = var.connection_draining
  connection_draining_timeout = var.connection_draining_timeout
  
  tags = merge(var.tags, {
    Name = "${var.environment}-digit-lb"
  })
}

# Access logs bucket
resource "aws_s3_bucket" "lb_logs" {
  bucket = "${var.environment}-digit-lb-logs"
  
  tags = merge(var.tags, {
    Name = "${var.environment}-lb-logs"
  })
}

resource "aws_s3_bucket_server_side_encryption_configuration" "lb_logs" {
  bucket = aws_s3_bucket.lb_logs.id
  
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "lb_logs" {
  bucket = aws_s3_bucket.lb_logs.id
  
  rule {
    id     = "expire-logs"
    status = "Enabled"
    
    expiration {
      days = 90
    }
  }
}

resource "aws_s3_bucket_policy" "lb_logs" {
  bucket = aws_s3_bucket.lb_logs.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_elb_service_account.main.id}:root"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.lb_logs.arn}/*"
      }
    ]
  })
}

data "aws_elb_service_account" "main" {}

# Store DNS name in SSM
resource "aws_ssm_parameter" "lb_dns" {
  name  = "/${var.environment}/loadbalancer/dns"
  type  = "String"
  value = aws_elb.main.dns_name
  
  tags = var.tags
}