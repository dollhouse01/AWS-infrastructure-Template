# SNS Topic for Operational Alerts
resource "aws_sns_topic" "operational_alerts" {
  name = "${var.environment}-operational-alerts"
  
  tags = {
    Environment = var.environment
    Purpose     = "Operational Alerts"
  }
}

# Email subscription for operations team
resource "aws_sns_topic_subscription" "operations_email" {
  count = var.operations_email != "" ? 1 : 0
  
  topic_arn = aws_sns_topic.operational_alerts.arn
  protocol  = "email"
  endpoint  = var.operations_email
}

# Slack subscription (if webhook provided)
resource "aws_sns_topic_subscription" "slack" {
  count = var.slack_webhook_url != "" ? 1 : 0
  
  topic_arn = aws_sns_topic.operational_alerts.arn
  protocol  = "https"
  endpoint  = var.slack_webhook_url
}

# CloudWatch Alarm for High CPU
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "${var.environment}-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period             = "300"
  statistic          = "Average"
  threshold          = "80"
  alarm_description  = "This alarm monitors EC2 CPU utilization"
  alarm_actions      = [aws_sns_topic.operational_alerts.arn]
  
  dimensions = {
    AutoScalingGroupName = var.asg_name
  }
}

# CloudWatch Alarm for RDS Connections
resource "aws_cloudwatch_metric_alarm" "rds_connections" {
  alarm_name          = "${var.environment}-rds-high-connections"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period             = "300"
  statistic          = "Average"
  threshold          = var.max_db_connections * 0.8
  alarm_description  = "Database connections approaching limit"
  alarm_actions      = [aws_sns_topic.operational_alerts.arn]
  
  dimensions = {
    DBInstanceIdentifier = var.db_instance_id
  }
}

# CloudWatch Alarm for Kafka Under Replicated Partitions
resource "aws_cloudwatch_metric_alarm" "kafka_under_replicated" {
  alarm_name          = "${var.environment}-kafka-under-replicated"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "KafkaDataLogsKafkaAppInfoValue"
  namespace           = "AWS/Kafka"
  period             = "300"
  statistic          = "Average"
  threshold          = "0"
  alarm_description  = "Kafka has under-replicated partitions"
  alarm_actions      = [aws_sns_topic.operational_alerts.arn]
  
  dimensions = {
    Cluster_Name = var.kafka_cluster_name
  }
}

# CloudWatch Alarm for EKS Node Down
resource "aws_cloudwatch_metric_alarm" "eks_node_down" {
  alarm_name          = "${var.environment}-eks-node-down"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "node_count"
  namespace           = "AWS/EKS"
  period             = "300"
  statistic          = "Average"
  threshold          = var.expected_nodes * 0.8
  alarm_description  = "EKS node count below expected"
  alarm_actions      = [aws_sns_topic.operational_alerts.arn]
  
  dimensions = {
    Cluster_Name = var.eks_cluster_name
  }
}

# Variables for operational alerts
variable "environment" {
  description = "Environment name"
  type        = string
}

variable "operations_email" {
  description = "Email for operational alerts"
  type        = string
  default     = ""
}

variable "slack_webhook_url" {
  description = "Slack webhook URL for alerts"
  type        = string
  default     = ""
  sensitive   = true
}

variable "asg_name" {
  description = "Auto Scaling Group name"
  type        = string
  default     = ""
}

variable "db_instance_id" {
  description = "RDS instance identifier"
  type        = string
  default     = ""
}

variable "max_db_connections" {
  description = "Maximum database connections"
  type        = number
  default     = 1000
}

variable "kafka_cluster_name" {
  description = "Kafka cluster name"
  type        = string
  default     = ""
}

variable "eks_cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = ""
}

variable "expected_nodes" {
  description = "Expected number of EKS nodes"
  type        = number
  default     = 3
}

# Outputs
output "operational_topic_arn" {
  description = "ARN of operational alerts SNS topic"
  value       = aws_sns_topic.operational_alerts.arn
}

output "cloudwatch_alarms" {
  description = "List of created CloudWatch alarms"
  value = [
    aws_cloudwatch_metric_alarm.high_cpu.id,
    aws_cloudwatch_metric_alarm.rds_connections.id,
    aws_cloudwatch_metric_alarm.kafka_under_replicated.id,
    aws_cloudwatch_metric_alarm.eks_node_down.id
  ]
}