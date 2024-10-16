output "t2s_services_cluster_endpoint" {
  description = "Endpoint for t2s-services EKS control plane"
  value       = module.eks.cluster_endpoint
}

output "t2s_services_cluster_security_group_id" {
  description = "Security group IDs attached to the t2s-services cluster control plane"
  value       = module.eks.cluster_security_group_id
}

output "t2s_services_region" {
  description = "AWS region for t2s-services"
  value       = var.region
}

output "t2s_services_cluster_name" {
  description = "Kubernetes Cluster Name for t2s-services"
  value       = module.eks.cluster_name
}