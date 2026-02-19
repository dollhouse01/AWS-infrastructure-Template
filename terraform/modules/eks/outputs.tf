output "cluster_id" {
  description = "EKS cluster ID"
  value       = aws_eks_cluster.main.id
}

output "cluster_name" {
  description = "EKS cluster name"
  value       = aws_eks_cluster.main.name
}

output "cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = aws_eks_cluster.main.endpoint
}

output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = aws_eks_cluster.main.vpc_config[0].cluster_security_group_id
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = aws_eks_cluster.main.certificate_authority[0].data
}

output "cluster_arn" {
  description = "ARN of the EKS cluster"
  value       = aws_eks_cluster.main.arn
}

output "cluster_version" {
  description = "Kubernetes version of the cluster"
  value       = aws_eks_cluster.main.version
}

output "cluster_oidc_issuer_url" {
  description = "URL of the OIDC issuer"
  value       = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

output "cluster_oidc_provider_arn" {
  description = "ARN of the OIDC Provider"
  value       = aws_iam_openid_connect_provider.eks.arn
}

output "node_group_arns" {
  description = "ARNs of the node groups"
  value       = { for k, v in aws_eks_node_group.main : k => v.arn }
}

output "node_group_ids" {
  description = "IDs of the node groups"
  value       = { for k, v in aws_eks_node_group.main : k => v.id }
}

output "node_group_status" {
  description = "Status of the node groups"
  value       = { for k, v in aws_eks_node_group.main : k => v.status }
}

output "spot_node_group_names" {
  description = "Names of spot node groups"
  value = {
    for k, v in aws_eks_node_group.main : k => v.node_group_name
    if v.capacity_type == "SPOT"
  }
}

output "on_demand_node_group_names" {
  description = "Names of on-demand node groups"
  value = {
    for k, v in aws_eks_node_group.main : k => v.node_group_name
    if v.capacity_type == "ON_DEMAND"
  }
}