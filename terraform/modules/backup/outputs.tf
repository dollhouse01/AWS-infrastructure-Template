output "backup_vault_id" {
  description = "ID of the main backup vault"
  value       = aws_backup_vault.main.id
}

output "backup_vault_arn" {
  description = "ARN of the main backup vault"
  value       = aws_backup_vault.main.arn
}

output "dr_vault_id" {
  description = "ID of the DR backup vault"
  value       = aws_backup_vault.cross_region.id
}

output "backup_plan_id" {
  description = "ID of the backup plan"
  value       = aws_backup_plan.database_backup.id
}

output "backup_plan_arn" {
  description = "ARN of the backup plan"
  value       = aws_backup_plan.database_backup.arn
}

output "iam_role_arn" {
  description = "ARN of the backup IAM role"
  value       = aws_iam_role.backup.arn
}

output "selection_id" {
  description = "ID of the backup selection"
  value       = aws_backup_selection.database_backup.id
}