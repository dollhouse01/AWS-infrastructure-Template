output "cluster_arn" {
  description = "ARN of the MSK cluster"
  value       = aws_msk_cluster.kafka.arn
}

output "cluster_name" {
  description = "Name of the MSK cluster"
  value       = aws_msk_cluster.kafka.cluster_name
}

output "bootstrap_brokers" {
  description = "Plaintext bootstrap brokers"
  value       = aws_msk_cluster.kafka.bootstrap_brokers
  sensitive   = true
}

output "bootstrap_brokers_tls" {
  description = "TLS bootstrap brokers"
  value       = aws_msk_cluster.kafka.bootstrap_brokers_tls
  sensitive   = true
}

output "bootstrap_brokers_sasl_scram" {
  description = "SASL/SCRAM bootstrap brokers"
  value       = aws_msk_cluster.kafka.bootstrap_brokers_sasl_scram
  sensitive   = true
}

output "zookeeper_connect_string" {
  description = "Zookeeper connect string"
  value       = aws_msk_cluster.kafka.zookeeper_connect_string
  sensitive   = true
}

output "security_group_id" {
  description = "MSK security group ID"
  value       = aws_security_group.msk.id
}

output "current_version" {
  description = "Current version of the MSK cluster"
  value       = aws_msk_cluster.kafka.current_version
}

output "configuration_arn" {
  description = "ARN of the MSK configuration"
  value       = aws_msk_configuration.config.arn
}

output "configuration_latest_revision" {
  description = "Latest revision of the MSK configuration"
  value       = aws_msk_configuration.config.latest_revision
}