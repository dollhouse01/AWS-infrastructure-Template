output "eks_service_role_arn" {
  description = "ARN of EKS service role"
  value       = aws_iam_role.eks_service.arn
}

output "eks_service_role_name" {
  description = "Name of EKS service role"
  value       = aws_iam_role.eks_service.name
}

output "eks_node_role_arn" {
  description = "ARN of EKS node role"
  value       = aws_iam_role.eks_node.arn
}

output "eks_node_role_name" {
  description = "Name of EKS node role"
  value       = aws_iam_role.eks_node.name
}

output "rds_monitoring_role_arn" {
  description = "ARN of RDS monitoring role"
  value       = aws_iam_role.rds_monitoring.arn
}

output "backup_role_arn" {
  description = "ARN of backup role"
  value       = aws_iam_role.backup.arn
}