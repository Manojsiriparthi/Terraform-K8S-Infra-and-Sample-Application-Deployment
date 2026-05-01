# ============================================================================
# OIDC PROVIDER
# ============================================================================
# OIDC provider is created in 1-infrastructure and referenced here
# This file contains data sources to retrieve OIDC information
# ============================================================================

# OIDC provider is already created in 1-infrastructure
# We retrieve it via remote state in locals.tf

# Data source to get OIDC provider details
data "aws_iam_openid_connect_provider" "eks" {
  arn = local.oidc_provider_arn
}
