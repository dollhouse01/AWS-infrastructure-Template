variable "environment" {
  description = "Environment name"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "af-south-1"
}

variable "dr_region" {
  description = "Disaster recovery region"
  type        = string
  default     = "eu-west-1"
}

variable "backup_retention_days" {
  description = "Days to keep backups"
  type        = number
  default     = 90
}

variable "cross_region_retention_days" {
  description = "Days to keep cross-region backups"
  type        = number
  default     = 365
}

variable "rds_resource_arn" {
  description = "ARN of RDS instance to backup"
  type        = string
  default     = ""
}

variable "efs_resource_arn" {
  description = "ARN of EFS filesystem to backup"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}