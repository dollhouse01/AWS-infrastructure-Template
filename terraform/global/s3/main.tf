# Terraform state bucket
resource "aws_s3_bucket" "terraform_state" {
  bucket = "digit-hcm-terraform-state-${var.account_id}"
  
  tags = merge(var.tags, {
    Name = "digit-hcm-terraform-state"
  })
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# DynamoDB for state locking
resource "aws_dynamodb_table" "terraform_lock" {
  name         = "terraform-state-lock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"
  
  attribute {
    name = "LockID"
    type = "S"
  }
  
  tags = merge(var.tags, {
    Name = "terraform-state-lock"
  })
}

# Backup bucket
resource "aws_s3_bucket" "backups" {
  bucket = "digit-hcm-backups-${var.account_id}"
  
  tags = merge(var.tags, {
    Name = "digit-hcm-backups"
  })
}

resource "aws_s3_bucket_versioning" "backups" {
  bucket = aws_s3_bucket.backups.id
  
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "backups" {
  bucket = aws_s3_bucket.backups.id
  
  rule {
    id     = "expire-old-backups"
    status = "Enabled"
    
    expiration {
      days = 90
    }
    
    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }
    
    transition {
      days          = 60
      storage_class = "GLACIER"
    }
  }
}

# Application artifacts bucket
resource "aws_s3_bucket" "artifacts" {
  bucket = "digit-hcm-artifacts-${var.account_id}"
  
  tags = merge(var.tags, {
    Name = "digit-hcm-artifacts"
  })
}

resource "aws_s3_bucket_versioning" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id
  
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id
  
  rule {
    id     = "expire-old-artifacts"
    status = "Enabled"
    
    expiration {
      days = 30
    }
  }
}