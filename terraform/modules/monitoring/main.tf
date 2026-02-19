# Security group for monitoring instances
resource "aws_security_group" "monitoring" {
  name        = "${var.environment}-monitoring-sg"
  description = "Security group for monitoring"
  vpc_id      = var.vpc_id
  
  ingress {
    description = "Prometheus from VPC"
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]
  }
  
  ingress {
    description = "Grafana from VPC"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]
  }
  
  ingress {
    description = "Alertmanager from VPC"
    from_port   = 9093
    to_port     = 9093
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]
  }
  
  ingress {
    description = "Node Exporter from VPC"
    from_port   = 9100
    to_port     = 9100
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = merge(var.tags, {
    Name = "${var.environment}-monitoring-sg"
  })
}

# EBS volumes for monitoring data
resource "aws_ebs_volume" "monitoring" {
  count = var.volume_count
  
  availability_zone = var.private_subnet_ids[count.index % length(var.private_subnet_ids)]
  size              = var.ebs_volume_size
  type              = "gp3"
  encrypted         = true
  
  tags = merge(var.tags, {
    Name = "${var.environment}-monitoring-data-${count.index + 1}"
  })
}

# CloudWatch Log Group for monitoring logs
resource "aws_cloudwatch_log_group" "monitoring" {
  name = "/${var.environment}/monitoring"
  retention_in_days = 30
  
  tags = var.tags
}

# SNS Topic for alerts
resource "aws_sns_topic" "alerts" {
  name = "${var.environment}-monitoring-alerts"
  
  tags = var.tags
}

resource "aws_sns_topic_subscription" "alerts_email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = "alerts-${var.environment}@example.com"
}

# CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.environment}-digit-hcm"
  
  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/EC2", "CPUUtilization", { stat = "Average" }],
            ["AWS/RDS", "DatabaseConnections", { stat = "Average" }]
          ]
          period = 300
          stat   = "Average"
          region = var.region
          title  = "EC2 and RDS Metrics"
        }
      }
    ]
  })
}

# Store monitoring configuration in SSM
resource "aws_ssm_parameter" "prometheus_endpoint" {
  name  = "/${var.environment}/monitoring/prometheus/endpoint"
  type  = "String"
  value = "prometheus.${var.environment}.internal:9090"
  
  tags = var.tags
}

resource "aws_ssm_parameter" "grafana_endpoint" {
  name  = "/${var.environment}/monitoring/grafana/endpoint"
  type  = "String"
  value = "grafana.${var.environment}.internal:3000"
  
  tags = var.tags
}

resource "aws_ssm_parameter" "alert_topic_arn" {
  name  = "/${var.environment}/monitoring/alerts/topic-arn"
  type  = "String"
  value = aws_sns_topic.alerts.arn
  
  tags = var.tags
}