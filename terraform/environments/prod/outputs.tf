output "vpc_id" {
  description = "VPC ID"
  value       = module.networking.vpc_id
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = module.networking.private_subnet_ids
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.networking.public_subnet_ids
}

output "eks_cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.eks.cluster_endpoint
}

output "eks_cluster_security_group_id" {
  description = "EKS cluster security group ID"
  value       = module.eks.cluster_security_group_id
}

output "rds_primary_endpoint" {
  description = "RDS primary endpoint"
  value       = module.rds.endpoint
}

output "rds_replica_endpoint" {
  description = "RDS replica endpoint"
  value       = module.rds.replica_endpoint
}

output "rds_security_group_id" {
  description = "RDS security group ID"
  value       = module.rds.security_group_id
}

output "elasticache_endpoint" {
  description = "ElastiCache endpoint"
  value       = module.elasticache.endpoint
}

output "elasticache_security_group_id" {
  description = "ElastiCache security group ID"
  value       = module.elasticache.security_group_id
}

output "msk_bootstrap_brokers" {
  description = "MSK bootstrap brokers"
  value       = module.msk.bootstrap_brokers
  sensitive   = true
}

output "msk_security_group_id" {
  description = "MSK security group ID"
  value       = module.msk.security_group_id
}

output "nat_gateway_public_ips" {
  description = "NAT Gateway public IPs"
  value       = module.networking.nat_gateway_public_ips
}

output "load_balancer_dns" {
  description = "Load balancer DNS name"
  value       = module.loadbalancer.dns_name
}

output "load_balancer_security_group_id" {
  description = "Load balancer security group ID"
  value       = module.loadbalancer.security_group_id
}

output "monitoring_endpoints" {
  description = "Monitoring endpoints"
  value       = module.monitoring.endpoints
  sensitive   = true  # Add this line
}
