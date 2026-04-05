variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "cluster_version" {
  description = "EKS cluster version"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs"
  type        = list(string)
}

variable "public_subnet_ids" {
  description = "Public subnet IDs"
  type        = list(string)
}

variable "cluster_role_arn" {
  description = "EKS cluster IAM role ARN"
  type        = string
}

variable "node_role_arn" {
  description = "EKS node IAM role ARN"
  type        = string
}

variable "enabled_cluster_log_types" {
  description = "EKS control plane log types"
  type        = list(string)
}

variable "private_node_instance_types" {
  description = "Private node instance types"
  type        = list(string)
}

variable "private_node_desired_size" {
  description = "Private node desired count"
  type        = number
}

variable "private_node_min_size" {
  description = "Private node minimum count"
  type        = number
}

variable "private_node_max_size" {
  description = "Private node maximum count"
  type        = number
}

variable "public_node_instance_types" {
  description = "Public node instance types"
  type        = list(string)
}

variable "public_node_desired_size" {
  description = "Public node desired count"
  type        = number
}

variable "public_node_min_size" {
  description = "Public node minimum count"
  type        = number
}

variable "public_node_max_size" {
  description = "Public node maximum count"
  type        = number
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
}

variable "eks_secrets_kms_key_arn" {
  description = "KMS key ARN for EKS secrets encryption"
  type        = string
}

variable "persistent_node_instance_types" {
  description = "Persistent node instance types (for database/stateful workloads)"
  type        = list(string)
}

variable "persistent_node_desired_size" {
  description = "Persistent node desired count"
  type        = number
}

variable "persistent_node_min_size" {
  description = "Persistent node minimum count"
  type        = number
}

variable "persistent_node_max_size" {
  description = "Persistent node maximum count"
  type        = number
}

variable "persistent_node_disk_size" {
  description = "Persistent node disk size in GB"
  type        = number
}
