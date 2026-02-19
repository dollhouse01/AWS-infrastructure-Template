variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "af-south-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "prod"
}

variable "active_start_date" {
  description = "Start of active period (format: YYYY-MM-DD)"
  type        = string
  default     = "2024-06-01"
}

variable "active_end_date" {
  description = "End of active period (format: YYYY-MM-DD)"
  type        = string
  default     = "2024-10-15"
}

variable "use_spot_instances" {
  description = "Whether to use spot instances"
  type        = bool
  default     = true
}

variable "current_period" {
  description = "Current period (active or idle)"
  type        = string
  default     = "idle"
}