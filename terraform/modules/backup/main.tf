# AWS Backup Plan - Safe retention policy
resource "aws_backup_plan" "database_backup" {
  name = "database-backup-plan"

  rule {
    rule_name         = "daily_backups"
    target_vault_name = aws_backup_vault.main.name
    schedule          = "cron(0 5 * * ? *)"  # Daily at 5 AM
    
    lifecycle {
      delete_after = 90  # Keep for 90 days, then move to cold storage
    }
    
    copy_action {
      destination_vault_arn = aws_backup_vault.cross_region.arn
      lifecycle {
        delete_after = 365  # Keep cross-region copy for 1 year
      }
    }
  }
  
  rule {
    rule_name         = "monthly_archives"
    target_vault_name = aws_backup_vault.main.name
    schedule          = "cron(0 6 1 * ? *)"  # 1st of month at 6 AM
    
    lifecycle {
      delete_after = 365  # Keep monthly archives for 1 year
    }
  }
}

# Separate vault for long-term retention
resource "aws_backup_vault" "main" {
  name = "digit-hcm-backup-vault"
}

resource "aws_backup_vault" "cross_region" {
  name = "digit-hcm-backup-vault-dr"
  region = "eu-west-1"  # Different region for disaster recovery
}