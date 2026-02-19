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

variable "private_subnet_ids" {
  description = "Private subnet IDs"
  type        = list(string)
}

variable "public_subnet_ids" {
  description = "Public subnet IDs"
  type        = list(string)
}

variable "node_groups" {
  description = "EKS managed node groups configuration"
  type = map(object({
    desired_size        = number
    min_size           = number
    max_size           = number
    instance_types     = list(string)
    spot_instance_types = optional(list(string))
    capacity_type      = string  # "ON_DEMAND" or "SPOT"
    use_spot           = bool
    k8s_labels         = map(string)
    taints = optional(list(object({
      key    = string
      value  = string
      effect = string
    })), [])
  }))
}

variable "cluster_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.27"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
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