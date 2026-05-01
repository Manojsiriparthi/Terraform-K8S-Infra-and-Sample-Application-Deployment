# ============================================================================
# EKS ADDONS VARIABLES
# ============================================================================

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "shopease"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "enable_gateway_api" {
  description = "Enable Gateway API CRDs (optional - Ingress already works)"
  type        = bool
  default     = false
}
