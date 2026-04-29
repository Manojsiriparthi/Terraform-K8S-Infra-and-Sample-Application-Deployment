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

# Bastion Configuration — access via SSM Session Manager (no SSH key needed)
bastion_instance_type = "t3.micro"

# EKS Configuration
cluster_version           = "1.32"
enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

# General Node Group (Application Workloads — no taint)
general_node_instance_types = ["t3.large"]
general_node_desired_size   = 3   # one per AZ
general_node_min_size       = 3
general_node_max_size       = 9

# Database Node Group (taint: workload=database:NoSchedule)
database_node_instance_types = ["r6i.xlarge"]  # memory-optimised for databases
database_node_desired_size   = 3               # one per AZ
database_node_min_size       = 3
database_node_max_size       = 6
database_node_disk_size      = 100

# GPU Node Group (taint: workload=gpu:NoSchedule)
gpu_node_instance_types = ["g4dn.xlarge"]  # NVIDIA T4 GPU
gpu_node_desired_size   = 1
gpu_node_min_size       = 0   # scale to zero when idle
gpu_node_max_size       = 3
gpu_node_disk_size      = 100
