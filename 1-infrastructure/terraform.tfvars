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

# VPC Configuration - PRODUCTION: 3 AZs for high availability
vpc_cidr             = "10.2.0.0/16"
availability_zones   = ["us-east-1a", "us-east-1b", "us-east-1c"]
public_subnet_cidrs  = ["10.2.1.0/24", "10.2.2.0/24", "10.2.3.0/24"]
private_subnet_cidrs = ["10.2.10.0/24", "10.2.20.0/24", "10.2.30.0/24"]

# Bastion Configuration
bastion_instance_type = "t3.micro"
bastion_key_name      = "terraform"  # Must exist in AWS Console (EC2 → Key Pairs)
bastion_allowed_cidrs = ["0.0.0.0/0"]  # PRODUCTION: Restrict to your office/VPN IP before deployment

# EKS Configuration
cluster_version           = "1.32"
enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

# Private Node Group (Application Workloads)
private_node_instance_types = ["t3.large"]  # Upgraded for production
private_node_desired_size   = 3  # One per AZ
private_node_min_size       = 3
private_node_max_size       = 9

# Public Node Group (Ingress/Load Balancers)
public_node_instance_types = ["t3.medium"]  # Upgraded for production
public_node_desired_size   = 2
public_node_min_size       = 2
public_node_max_size       = 4

# Persistent Node Group (Database/Stateful Workloads)
persistent_node_instance_types = ["t3.xlarge"]  # Dedicated for database
persistent_node_desired_size   = 3  # One per AZ for HA
persistent_node_min_size       = 3
persistent_node_max_size       = 6
persistent_node_disk_size      = 100  # Larger disk for database nodes
