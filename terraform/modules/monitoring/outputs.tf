output "security_group_id" {
  description = "Monitoring security group ID"
  value       = aws_security_group.monitoring.id
}

output "ebs_volume_ids" {
  description = "Monitoring EBS volume IDs"
  value       = aws_ebs_volume.monitoring[*].id
}

output "cloudwatch_log_group" {
  description = "CloudWatch log group name"
  value       = aws_cloudwatch_log_group.monitoring.name
}

output "sns_topic_arn" {
  description = "SNS topic ARN for alerts"
  value       = aws_sns_topic.alerts.arn
}

output "dashboard_name" {
  description = "CloudWatch dashboard name"
  value       = aws_cloudwatch_dashboard.main.dashboard_name
}

output "endpoints" {
  description = "Monitoring endpoints"
  value = {
    prometheus = aws_ssm_parameter.prometheus_endpoint.value
    grafana    = aws_ssm_parameter.grafana_endpoint.value
  }
}