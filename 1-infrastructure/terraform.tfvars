# ============================================================================
# TERRAFORM VARIABLES EXAMPLE
# Copy this file to terraform.tfvars and update with your values
# ============================================================================

# Global Configuration
aws_region  = "us-east-1"
project_name = "shopease"
environment  = "production"

# Tagging
owner_email = "devops@shopease.com"
created_by  = "john.doe"
cost_center = "engineering"

# VPC Configuration
vpc_cidr             = "10.2.0.0/16"
availability_zones   = ["us-east-1a", "us-east-1b"]
public_subnet_cidrs  = ["10.2.1.0/24", "10.2.2.0/24"]
private_subnet_cidrs = ["10.2.10.0/24", "10.2.20.0/24"]

# Bastion Configuration
bastion_instance_type = "t3.micro"
bastion_key_name      = "terraform"  # Must exist in AWS Console (EC2 → Key Pairs)
bastion_allowed_cidrs = ["0.0.0.0/0"]  # PRODUCTION: Change to your office/home IP (e.g., ["203.0.113.0/32"])

# EKS Configuration
cluster_version           = "1.29"
enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

# Private Node Group
private_node_instance_types = ["t3.medium"]
private_node_desired_size   = 2
private_node_min_size       = 1
private_node_max_size       = 4

# Public Node Group
public_node_instance_types = ["t3.small"]
public_node_desired_size   = 1
public_node_min_size       = 1
public_node_max_size       = 2
