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
# Add these to your existing variables.tf file

variable "database_username" {
  description = "Username for RDS database"
  type        = string
  default     = "digithcm_admin"
}

variable "database_password" {
  description = "Password for RDS database (if not provided, random will be generated)"
  type        = string
  sensitive   = true
  default     = null
}

variable "database_name" {
  description = "Name of the database"
  type        = string
  default     = "digithcm_prod"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.2.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["af-south-1a", "af-south-1b"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.2.1.0/24", "10.2.2.0/24"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.2.101.0/24", "10.2.102.0/24"]
}

variable "ssl_certificate_id" {
  description = "SSL certificate ARN for HTTPS listener"
  type        = string
  default     = ""
}
