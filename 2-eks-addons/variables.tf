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

variable "enable_gateway_api" {
  description = "Enable Gateway API CRDs (optional - Ingress already works)"
  type        = bool
  default     = false
}

# Tagging variables
variable "owner_email" {
  description = "Owner email for tagging"
  type        = string
  default     = "devops@shopease.com"
}

variable "created_by" {
  description = "Created by for tagging"
  type        = string
  default     = "platform-team"
}

variable "cost_center" {
  description = "Cost center for tagging"
  type        = string
  default     = "engineering"
}

# Addon enable/disable flags
variable "enable_aws_load_balancer_controller" {
  description = "Enable AWS Load Balancer Controller"
  type        = bool
  default     = true
}

variable "enable_external_dns" {
  description = "Enable External DNS"
  type        = bool
  default     = false
}

variable "enable_cert_manager" {
  description = "Enable Cert Manager"
  type        = bool
  default     = false
}

variable "enable_metrics_server" {
  description = "Enable Metrics Server"
  type        = bool
  default     = true
}

variable "enable_karpenter" {
  description = "Enable Karpenter autoscaler"
  type        = bool
  default     = false
}

variable "enable_vpa" {
  description = "Enable Vertical Pod Autoscaler"
  type        = bool
  default     = false
}

variable "enable_fluent_bit" {
  description = "Enable Fluent Bit for logging"
  type        = bool
  default     = true
}

variable "enable_cloudwatch_observability" {
  description = "Enable CloudWatch Observability"
  type        = bool
  default     = true
}
