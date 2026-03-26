# ============================================================================
# EKS MODULE - PRODUCTION GRADE SECURITY
# ============================================================================

# EKS Cluster Security Group
resource "aws_security_group" "eks_cluster" {
  name        = "${var.project_name}-${var.environment}-eks-cluster-sg"
  description = "Security group for EKS cluster control plane"
  vpc_id      = var.vpc_id

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-eks-cluster-sg"
    }
  )
}

# Cluster SG Rule: Allow HTTPS from nodes
resource "aws_security_group_rule" "cluster_ingress_nodes_https" {
  type                     = "ingress"
  description              = "HTTPS from worker nodes"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_cluster.id
  source_security_group_id = aws_security_group.eks_nodes.id
}

# Cluster SG Rule: Allow all outbound
resource "aws_security_group_rule" "cluster_egress_all" {
  type              = "egress"
  description       = "Allow all outbound"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.eks_cluster.id
}

# EKS Node Security Group - Production Grade
resource "aws_security_group" "eks_nodes" {
  name        = "${var.project_name}-${var.environment}-eks-nodes-sg"
  description = "Security group for EKS worker nodes - production grade"
  vpc_id      = var.vpc_id

  tags = merge(
    var.common_tags,
    {
      Name                                        = "${var.project_name}-${var.environment}-eks-nodes-sg"
      "kubernetes.io/cluster/${var.cluster_name}" = "owned"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# Node SG Rule: Node to node communication
resource "aws_security_group_rule" "nodes_ingress_self" {
  type              = "ingress"
  description       = "Node to node communication"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.eks_nodes.id
  self              = true
}

# Node SG Rule: Cluster API to node
resource "aws_security_group_rule" "nodes_ingress_cluster_https" {
  type                     = "ingress"
  description              = "Cluster API to node"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_nodes.id
  source_security_group_id = aws_security_group.eks_cluster.id
}

# Node SG Rule: Cluster to node kubelet
resource "aws_security_group_rule" "nodes_ingress_cluster_kubelet" {
  type                     = "ingress"
  description              = "Cluster to node kubelet"
  from_port                = 10250
  to_port                  = 10250
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_nodes.id
  source_security_group_id = aws_security_group.eks_cluster.id
}

# Node SG Rule: CoreDNS TCP
resource "aws_security_group_rule" "nodes_ingress_coredns_tcp" {
  type              = "ingress"
  description       = "CoreDNS TCP"
  from_port         = 53
  to_port           = 53
  protocol          = "tcp"
  security_group_id = aws_security_group.eks_nodes.id
  self              = true
}

# Node SG Rule: CoreDNS UDP
resource "aws_security_group_rule" "nodes_ingress_coredns_udp" {
  type              = "ingress"
  description       = "CoreDNS UDP"
  from_port         = 53
  to_port           = 53
  protocol          = "udp"
  security_group_id = aws_security_group.eks_nodes.id
  self              = true
}

# Node SG Rule: NodePort services from VPC only
resource "aws_security_group_rule" "nodes_ingress_nodeport" {
  type              = "ingress"
  description       = "NodePort services from VPC"
  from_port         = 30000
  to_port           = 32767
  protocol          = "tcp"
  cidr_blocks       = [var.vpc_cidr]
  security_group_id = aws_security_group.eks_nodes.id
}

# Node SG Rule: Allow all outbound
resource "aws_security_group_rule" "nodes_egress_all" {
  type              = "egress"
  description       = "Allow all outbound"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.eks_nodes.id
}

# EKS Cluster
resource "aws_eks_cluster" "main" {
  name     = var.cluster_name
  role_arn = var.cluster_role_arn
  version  = var.cluster_version

  vpc_config {
    subnet_ids              = concat(var.private_subnet_ids, var.public_subnet_ids)
    endpoint_private_access = true
    endpoint_public_access  = false
    security_group_ids      = [aws_security_group.eks_cluster.id]
  }

  enabled_cluster_log_types = var.enabled_cluster_log_types

  access_config {
    authentication_mode                         = "CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = true
  }

  tags = var.common_tags

  depends_on = [
    aws_security_group.eks_cluster,
    aws_security_group.eks_nodes
  ]

  lifecycle {
    ignore_changes = [access_config[0].bootstrap_cluster_creator_admin_permissions]
  }
}

# Private Node Group (for application workloads)
resource "aws_eks_node_group" "private" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.project_name}-${var.environment}-private-nodes"
  node_role_arn   = var.node_role_arn
  subnet_ids      = var.private_subnet_ids

  instance_types = var.private_node_instance_types
  capacity_type  = "ON_DEMAND"
  disk_size      = 50

  scaling_config {
    desired_size = var.private_node_desired_size
    min_size     = var.private_node_min_size
    max_size     = var.private_node_max_size
  }

  update_config {
    max_unavailable = 1
  }

  labels = {
    role        = "private"
    environment = var.environment
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-private-node-group"
    }
  )

  depends_on = [aws_eks_cluster.main]

  lifecycle {
    ignore_changes = [scaling_config[0].desired_size]
  }
}

# Public Node Group (for load balancers and ingress)
resource "aws_eks_node_group" "public" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.project_name}-${var.environment}-public-nodes"
  node_role_arn   = var.node_role_arn
  subnet_ids      = var.public_subnet_ids

  instance_types = var.public_node_instance_types
  capacity_type  = "ON_DEMAND"
  disk_size      = 30

  scaling_config {
    desired_size = var.public_node_desired_size
    min_size     = var.public_node_min_size
    max_size     = var.public_node_max_size
  }

  update_config {
    max_unavailable = 1
  }

  labels = {
    role        = "public"
    environment = var.environment
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-public-node-group"
    }
  )

  depends_on = [aws_eks_cluster.main]

  lifecycle {
    ignore_changes = [scaling_config[0].desired_size]
  }
}

# EKS Addons
resource "aws_eks_addon" "vpc_cni" {
  cluster_name = aws_eks_cluster.main.name
  addon_name   = "vpc-cni"

  tags = var.common_tags

  depends_on = [
    aws_eks_node_group.private,
    aws_eks_node_group.public
  ]
}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name = aws_eks_cluster.main.name
  addon_name   = "kube-proxy"

  tags = var.common_tags

  depends_on = [
    aws_eks_node_group.private,
    aws_eks_node_group.public
  ]
}

resource "aws_eks_addon" "coredns" {
  cluster_name = aws_eks_cluster.main.name
  addon_name   = "coredns"

  tags = var.common_tags

  depends_on = [
    aws_eks_node_group.private,
    aws_eks_node_group.public
  ]
}
