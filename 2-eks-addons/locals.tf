# ============================================================================
# LOCAL VALUES
# ============================================================================
# Computed values used across addon resources
# Most values are retrieved from 1-infrastructure outputs via data sources
# ============================================================================

locals {
  # Cluster information from data sources
  cluster_name        = data.aws_eks_cluster.cluster.name
  cluster_endpoint    = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_cert     = data.aws_eks_cluster.cluster.certificate_authority[0].data
  cluster_version     = data.aws_eks_cluster.cluster.version
  
  # OIDC provider information
  oidc_provider_arn   = data.terraform_remote_state.infrastructure.outputs.cluster_oidc_provider_arn
  oidc_provider_url   = data.terraform_remote_state.infrastructure.outputs.cluster_oidc_issuer_url
  
  # VPC information
  vpc_id              = data.terraform_remote_state.infrastructure.outputs.vpc_id
  private_subnet_ids  = data.terraform_remote_state.infrastructure.outputs.private_subnet_ids
  
  # Common tags
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    Owner       = var.owner_email
    CreatedBy   = var.created_by
    CostCenter  = var.cost_center
  }
}
