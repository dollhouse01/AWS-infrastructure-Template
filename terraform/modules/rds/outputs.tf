output "primary_id" {
  description = "RDS primary instance ID"
  value       = aws_db_instance.primary.id
}

output "endpoint" {
  description = "RDS primary endpoint"
  value       = aws_db_instance.primary.endpoint
}

output "address" {
  description = "RDS primary address"
  value       = aws_db_instance.primary.address
}

output "port" {
  description = "RDS port"
  value       = aws_db_instance.primary.port
}

output "arn" {
  description = "ARN of RDS primary instance"
  value       = aws_db_instance.primary.arn
}

output "security_group_id" {
  description = "Security group ID"
  value       = aws_security_group.rds.id
}

output "subnet_group_name" {
  description = "DB subnet group name"
  value       = aws_db_subnet_group.rds.name
}

output "parameter_group_name" {
  description = "DB parameter group name"
  value       = aws_db_parameter_group.postgres.name
}

output "database_name" {
  description = "Database name"
  value       = aws_db_instance.primary.db_name
}

output "database_username" {
  description = "Database username"
  value       = aws_db_instance.primary.username
  sensitive   = true
}

output "database_password" {
  description = "Database password"
  value       = local.database_password
  sensitive   = true
}

output "replica_endpoint" {
  description = "RDS replica endpoint"
  value       = var.create_read_replica ? aws_db_instance.replica[0].endpoint : null
}

output "secret_arn" {
  description = "ARN of the secret in Secrets Manager"
  value       = aws_secretsmanager_secret.database.arn
}