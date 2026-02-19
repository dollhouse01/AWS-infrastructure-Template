variable "environment" {
  description = "Environment name"
  type        = string
}

variable "bucket_name" {
  description = "Name of the S3 bucket"
  type        = string
}

variable "backup_retention_days" {
  description = "Days to keep backups in standard storage"
  type        = number
  default     = 30
}

variable "archive_retention_days" {
  description = "Days to keep archives in Glacier"
  type        = number
  default     = 365
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}