output "eks_cluster_endpoint" {
  description = "The endpoint for your EKS Kubernetes API"
  value       = module.eks.cluster_endpoint # Re-exporting from the EKS module
}

output "alb_dns_name" {
  description = "The DNS name of the Load Balancer (once provisioned by K8s)"
  value       = module.addons.alb_hostname
}
