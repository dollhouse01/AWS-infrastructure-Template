output "bucket_name" {
  description = "Name of the configured bucket"
  value       = var.bucket_name
}

output "lifecycle_rules" {
  description = "Number of lifecycle rules configured"
  value       = 3
}