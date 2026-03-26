# ============================================================================
# GLOBAL VARIABLES
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

variable "owner_email" {
  description = "Owner email for resource tagging"
  type        = string
}

variable "created_by" {
  description = "Username who created the resources"
  type        = string
}

variable "cost_center" {
  description = "Cost center for billing"
  type        = string
  default     = "engineering"
}

# ============================================================================
# VPC VARIABLES
# ============================================================================

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Availability zones"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDR blocks"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "Private subnet CIDR blocks"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.20.0/24"]
}

# ============================================================================
# BASTION VARIABLES
# ============================================================================

variable "bastion_instance_type" {
  description = "Bastion instance type"
  type        = string
  default     = "t3.micro"
}

variable "bastion_key_name" {
  description = "SSH key name for bastion (must exist in AWS Console)"
  type        = string
  default     = "terraform"
}

variable "bastion_allowed_cidrs" {
  description = "CIDR blocks allowed to SSH to bastion (restrict to your IP for production)"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

# ============================================================================
# EKS VARIABLES
# ============================================================================

variable "cluster_version" {
  description = "EKS cluster version"
  type        = string
  default     = "1.28"
}

variable "enabled_cluster_log_types" {
  description = "EKS control plane log types"
  type        = list(string)
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

variable "private_node_instance_types" {
  description = "Private node instance types"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "private_node_desired_size" {
  description = "Private node desired count"
  type        = number
  default     = 2
}

variable "private_node_min_size" {
  description = "Private node minimum count"
  type        = number
  default     = 1
}

variable "private_node_max_size" {
  description = "Private node maximum count"
  type        = number
  default     = 4
}

variable "public_node_instance_types" {
  description = "Public node instance types"
  type        = list(string)
  default     = ["t3.small"]
}

variable "public_node_desired_size" {
  description = "Public node desired count"
  type        = number
  default     = 1
}

variable "public_node_min_size" {
  description = "Public node minimum count"
  type        = number
  default     = 1
}

variable "public_node_max_size" {
  description = "Public node maximum count"
  type        = number
  default     = 2
}
