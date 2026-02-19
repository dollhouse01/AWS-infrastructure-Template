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

variable "broker_node_type" {
  description = "MSK broker node type"
  type        = string
}

variable "number_of_broker_nodes" {
  description = "Number of broker nodes"
  type        = number
}

variable "ebs_volume_size" {
  description = "EBS volume size per broker in GB"
  type        = number
}

variable "kafka_version" {
  description = "Kafka version"
  type        = string
  default     = "3.4.0"
}

variable "client_broker_encryption" {
  description = "Encryption setting for client-broker communication"
  type        = string
  default     = "TLS"
}

variable "enhanced_monitoring" {
  description = "Enhanced monitoring level"
  type        = string
  default     = "PER_BROKER"
}

variable "period" {
  description = "Current period (active or idle)"
  type        = string
  default     = "idle"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}