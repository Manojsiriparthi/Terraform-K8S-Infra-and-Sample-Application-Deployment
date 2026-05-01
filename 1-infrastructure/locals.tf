# ============================================================================
# LOCAL VALUES
# ============================================================================
# Computed values used across multiple resources
# ============================================================================

locals {
  # Cluster name used by EKS and VPC subnet tags
  cluster_name = "${var.project_name}-${var.environment}-cluster"

  # Common tags applied to all resources
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    Owner       = var.owner_email
    CreatedBy   = var.created_by
    CostCenter  = var.cost_center
  }
}
