# ============================================================================
# DEVELOPMENT ENVIRONMENT CONFIGURATION
# Usage: terraform apply -var-file="dev.tfvars"
# ============================================================================

# Global Configuration
aws_region   = "us-east-1"
project_name = "shopease"
environment  = "development"

# Tagging
owner_email = "manojs.devops1@gmail.com"
created_by  = "platform-team"
cost_center = "engineering"

# VPC Configuration - DEV: 2 AZs (cost optimization)
vpc_cidr             = "10.0.0.0/16"
availability_zones   = ["us-east-1a", "us-east-1b"]
public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs = ["10.0.10.0/24", "10.0.20.0/24"]

# Bastion Configuration
bastion_instance_type = "t3.micro"

# EKS Configuration
cluster_version           = "1.32"
enabled_cluster_log_types = ["api", "audit"]  # Reduced logging for dev

# General Node Group (Application Workloads)
# DEV: Smaller instances and fewer nodes
general_node_instance_types = ["t3.medium"]  # Smaller than prod
general_node_desired_size   = 2              # 1 per AZ
general_node_min_size       = 2
general_node_max_size       = 4              # Lower max for dev

# Database Node Group (taint: workload=database:NoSchedule)
# DEV: Smaller memory-optimized instances
database_node_instance_types = ["t3.medium"]  # Smaller than prod (r6i.xlarge)
database_node_desired_size   = 2           # Single node for dev
database_node_min_size       = 2
database_node_max_size       = 3
database_node_disk_size      = 50            # Smaller disk for dev

# GPU Node Group (taint: workload=gpu:NoSchedule)
# DEV: DISABLED - No GPU nodes in development to save costs
enable_gpu_nodes            = false
gpu_node_instance_types     = ["g4dn.xlarge"]
gpu_node_desired_size       = 0
gpu_node_min_size           = 0
gpu_node_max_size           = 1
gpu_node_disk_size          = 50

# To enable GPU nodes in dev, change enable_gpu_nodes to true and adjust sizes

# ============================================================================
# DEV ENVIRONMENT NOTES:
# ============================================================================
# - Uses 2 AZs instead of 3 (cost savings)
# - Smaller instance types (t3.medium vs t3.large/r6i.xlarge)
# - Fewer nodes (2-4 general, 1-2 database)
# - GPU nodes commented out (enable only if needed)
# - Reduced logging (api + audit only)
# - Smaller disk sizes (50GB vs 100GB)
# 
# Estimated Monthly Cost:
# - EKS Control Plane: $73
# - EC2 Nodes (2x t3.medium + 1x t3.medium): ~$100
# - NAT Gateways (2x): ~$65
# - EBS Volumes: ~$15
# - Total: ~$253/month (vs ~$500+ for prod)
# ============================================================================
