variable "environment" {
  description = "Environment name"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnet IDs"
  type        = list(string)
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "instance_count" {
  description = "Number of instances"
  type        = number
}

variable "ebs_volumes" {
  description = "EBS volumes configuration"
  type = map(object({
    size  = number
    count = number
    type  = string
  }))
}

variable "ami_id" {
  description = "AMI ID (if not provided, latest Amazon Linux 2 will be used)"
  type        = string
  default     = null
}

variable "key_name" {
  description = "Key pair name"
  type        = string
  default     = null
}

variable "user_data" {
  description = "User data script"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}