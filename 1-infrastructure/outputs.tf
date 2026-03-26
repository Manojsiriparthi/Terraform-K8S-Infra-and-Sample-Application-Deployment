# ============================================================================
# INFRASTRUCTURE OUTPUTS
# ============================================================================

# VPC Outputs
output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = module.vpc.private_subnet_ids
}

# Bastion Outputs
output "bastion_instance_id" {
  description = "Bastion instance ID"
  value       = module.ec2_bastion.bastion_instance_id
}

output "bastion_public_ip" {
  description = "Bastion public IP"
  value       = module.ec2_bastion.bastion_public_ip
}

output "bastion_key_name" {
  description = "SSH key name for bastion (PEM file: keys/<key-name>.pem)"
  value       = module.ec2_bastion.bastion_key_name
}

# EKS Outputs
output "cluster_id" {
  description = "EKS cluster ID"
  value       = module.eks.cluster_id
}

output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.eks.cluster_endpoint
}

output "cluster_certificate_authority_data" {
  description = "EKS cluster certificate authority data"
  value       = module.eks.cluster_certificate_authority_data
  sensitive   = true
}

output "cluster_security_group_id" {
  description = "EKS cluster security group ID"
  value       = module.eks.cluster_security_group_id
}

output "node_security_group_id" {
  description = "EKS node security group ID"
  value       = module.eks.node_security_group_id
}

output "cluster_oidc_issuer_url" {
  description = "OIDC issuer URL for IRSA (without https://)"
  value       = module.eks.cluster_oidc_issuer_url
}
