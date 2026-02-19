output "elb_id" {
  description = "ELB ID"
  value       = aws_elb.main.id
}

output "elb_name" {
  description = "ELB name"
  value       = aws_elb.main.name
}

output "dns_name" {
  description = "DNS name of the load balancer"
  value       = aws_elb.main.dns_name
}

output "zone_id" {
  description = "Zone ID of the load balancer"
  value       = aws_elb.main.zone_id
}

output "security_group_id" {
  description = "Security group ID of the load balancer"
  value       = aws_security_group.lb.id
}

output "source_security_group_id" {
  description = "Source security group ID"
  value       = aws_elb.main.source_security_group_id
}

output "instances" {
  description = "List of instances registered"
  value       = aws_elb.main.instances
}