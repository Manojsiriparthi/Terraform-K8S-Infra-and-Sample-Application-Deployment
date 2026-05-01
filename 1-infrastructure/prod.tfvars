# ============================================================================
# PRODUCTION ENVIRONMENT CONFIGURATION
# Usage: terraform apply -var-file="prod.tfvars"
# ============================================================================

# Global Configuration
aws_region   = "us-east-1"
project_name = "shopease"
environment  = "production"

# Tagging
owner_email = "devops@shopease.com"
created_by  = "platform-team"
cost_center = "engineering"

# VPC Configuration - PROD: 3 AZs for high availability
vpc_cidr             = "10.2.0.0/16"
availability_zones   = ["us-east-1a", "us-east-1b", "us-east-1c"]
public_subnet_cidrs  = ["10.2.1.0/24", "10.2.2.0/24", "10.2.3.0/24"]
private_subnet_cidrs = ["10.2.10.0/24", "10.2.20.0/24", "10.2.30.0/24"]

# Bastion Configuration
bastion_instance_type = "t3.micro"

# EKS Configuration
cluster_version           = "1.32"
enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

# General Node Group (Application Workloads — no taint)
# PROD: Larger instances for better performance
general_node_instance_types = ["t3.large"]   # Production-grade instances
general_node_desired_size   = 3              # One per AZ
general_node_min_size       = 3
general_node_max_size       = 9              # Can scale up to 9 nodes

# Database Node Group (taint: workload=database:NoSchedule)
# PROD: Memory-optimized instances for database workloads
database_node_instance_types = ["r6i.xlarge"]  # 4 vCPU, 32GB RAM
database_node_desired_size   = 3               # One per AZ for HA
database_node_min_size       = 3
database_node_max_size       = 6
database_node_disk_size      = 100

# GPU Node Group (taint: workload=gpu:NoSchedule)
# PROD: GPU instances for ML/AI workloads
gpu_node_instance_types = ["g4dn.xlarge"]  # NVIDIA T4 GPU, 4 vCPU, 16GB RAM
gpu_node_desired_size   = 1                # Start with 1 GPU node
gpu_node_min_size       = 0                # Can scale to zero when idle
gpu_node_max_size       = 3                # Max 3 GPU nodes
gpu_node_disk_size      = 100

# ============================================================================
# PRODUCTION ENVIRONMENT NOTES:
# ============================================================================
# - Uses 3 AZs for maximum availability
# - Production-grade instance types (t3.large, r6i.xlarge)
# - Higher node counts for redundancy
# - GPU nodes enabled for ML/AI workloads
# - Full control plane logging enabled
# - Larger disk sizes (100GB)
# 
# Estimated Monthly Cost:
# - EKS Control Plane: $73
# - EC2 Nodes:
#   - General (3x t3.large): ~$190
#   - Database (3x r6i.xlarge): ~$580
#   - GPU (1x g4dn.xlarge): ~$390
# - NAT Gateways (3x): ~$98
# - EBS Volumes: ~$50
# - Total: ~$1,381/month
# 
# High Availability Features:
# - Multi-AZ deployment (3 AZs)
# - Dedicated database nodes with taints
# - GPU nodes for specialized workloads
# - Auto-scaling enabled (can scale to 0 for GPU)
# - Full observability with all logs enabled
# ============================================================================
