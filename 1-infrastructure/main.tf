# ============================================================================
# MAIN INFRASTRUCTURE - MODULE ORCHESTRATION
# ============================================================================

# IAM Module
module "iam" {
  source = "./modules/iam"

  project_name = var.project_name
  environment  = var.environment
  common_tags  = local.common_tags
}

# VPC Module
module "vpc" {
  source = "./modules/vpc"

  project_name         = var.project_name
  environment          = var.environment
  vpc_cidr             = var.vpc_cidr
  availability_zones   = var.availability_zones
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  cluster_name         = local.cluster_name
  common_tags          = local.common_tags
}

# EC2 Bastion Module
module "ec2_bastion" {
  source = "./modules/ec2-bastion"

  project_name              = var.project_name
  environment               = var.environment
  vpc_id                    = module.vpc.vpc_id
  public_subnet_id          = module.vpc.public_subnet_ids[0]
  instance_type             = var.bastion_instance_type
  key_name                  = var.bastion_key_name
  allowed_cidrs             = var.bastion_allowed_cidrs
  iam_instance_profile_name = module.iam.bastion_instance_profile_name
  common_tags               = local.common_tags

  depends_on = [module.vpc, module.iam]
}

# EKS Module
module "eks" {
  source = "./modules/eks"

  project_name                = var.project_name
  environment                 = var.environment
  cluster_name                = local.cluster_name
  cluster_version             = var.cluster_version
  vpc_id                      = module.vpc.vpc_id
  vpc_cidr                    = var.vpc_cidr
  private_subnet_ids          = module.vpc.private_subnet_ids
  public_subnet_ids           = module.vpc.public_subnet_ids
  cluster_role_arn            = module.iam.eks_cluster_role_arn
  node_role_arn               = module.iam.eks_node_role_arn
  allowed_cidr_blocks         = var.allowed_cidr_blocks
  enabled_cluster_log_types   = var.enabled_cluster_log_types
  private_node_instance_types = var.private_node_instance_types
  private_node_desired_size   = var.private_node_desired_size
  private_node_min_size       = var.private_node_min_size
  private_node_max_size       = var.private_node_max_size
  public_node_instance_types  = var.public_node_instance_types
  public_node_desired_size    = var.public_node_desired_size
  public_node_min_size        = var.public_node_min_size
  public_node_max_size        = var.public_node_max_size
  common_tags                 = local.common_tags

  depends_on = [module.vpc, module.iam]
}
