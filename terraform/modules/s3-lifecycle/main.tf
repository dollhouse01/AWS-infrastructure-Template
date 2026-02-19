# Safe S3 lifecycle policy - NEVER deletes important data
resource "aws_s3_bucket_lifecycle_configuration" "backups" {
  bucket = var.bucket_name
  
  rule {
    id     = "move-old-backups-to-glacier"
    status = "Enabled"
    
    filter {
      prefix = "daily/"
    }
    
    # Move to cheaper storage, NEVER delete
    transition {
      days          = 30
      storage_class = "STANDARD_IA"    # Cheaper infrequent access
    }
    
    transition {
      days          = 60
      storage_class = "GLACIER"        # Cheapest archive storage
    }
    
    # NO EXPIRATION - we keep forever
  }
  
  rule {
    id     = "logs-retention"
    status = "Enabled"
    
    filter {
      prefix = "logs/"
    }
    
    # Logs can be deleted after 90 days (they're not critical data)
    expiration {
      days = 90
    }
  }
  
  rule {
    id     = "temp-file-cleanup"
    status = "Enabled"
    
    filter {
      prefix = "temp/"
    }
    
    # Temporary files can be deleted after 1 day
    expiration {
      days = 1
    }
  }
}