# ============================================================================
# EKS ADDONS CONFIGURATION
# ============================================================================
# This file contains configuration for EKS addons and cluster extensions
# Values are retrieved from 1-infrastructure outputs via data sources
# ============================================================================

# Cluster Configuration (retrieved from data sources in provider.tf)
# cluster_name, vpc_id, private_subnet_ids, etc. are fetched automatically

# AWS Region
aws_region = "us-east-1"

# Project Configuration
project_name = "shopease"
environment  = "development"

# Tagging
owner_email = "manojs.devops1@gmail.com"
created_by  = "platform-team"
cost_center = "engineering"

# ============================================================================
# ADDON CONFIGURATION
# ============================================================================

# Enable/Disable Addons
enable_aws_load_balancer_controller = true
enable_external_dns                 = true   # Enabled - requires Route53 domain
enable_cert_manager                 = false  # DISABLED - chart compatibility issue
enable_metrics_server               = true
enable_karpenter                    = true   # Enabled - advanced autoscaling (FIXED)
enable_vpa                          = true   # Enabled - Vertical Pod Autoscaler
enable_fluent_bit                   = true   # Enabled - logging (delete existing first)
enable_cloudwatch_observability     = true   # Monitoring
enable_gateway_api                  = true   # Enabled - Next-gen Ingress API (FIXED)

# ============================================================================
# NOTES:
# ============================================================================
# - Most values are automatically retrieved from 1-infrastructure outputs
# - Enable only the addons you need to reduce costs
# - External DNS and Cert Manager require domain configuration
# - Karpenter is for advanced autoscaling (optional)
# - Gateway API is for future migration from Ingress
# ============================================================================

