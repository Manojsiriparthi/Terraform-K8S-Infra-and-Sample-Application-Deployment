# ============================================================================
# EBS CSI DRIVER
# ============================================================================
# Required for persistent volumes (PVC) to work with EBS volumes
# Without this, StatefulSets with PVCs will remain in Pending state
# ============================================================================

# ── IRSA for EBS CSI Driver ──────────────────────────────────────────────────

data "aws_iam_policy_document" "ebs_csi_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Federated"
      identifiers = [local.oidc_provider_arn]
    }
    actions = ["sts:AssumeRoleWithWebIdentity"]
    condition {
      test     = "StringEquals"
      variable = "${local.oidc_provider_url}:sub"
      values   = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
    }
    condition {
      test     = "StringEquals"
      variable = "${local.oidc_provider_url}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ebs_csi" {
  name               = "${var.project_name}-${var.environment}-ebs-csi-driver"
  assume_role_policy = data.aws_iam_policy_document.ebs_csi_assume_role.json

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-ebs-csi-driver"
  })
}

# Attach AWS managed policy for EBS CSI Driver
resource "aws_iam_role_policy_attachment" "ebs_csi" {
  role       = aws_iam_role.ebs_csi.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

# ── EKS MANAGED ADDON ────────────────────────────────────────────────────────

resource "aws_eks_addon" "ebs_csi_driver" {
  cluster_name             = local.cluster_name
  addon_name               = "aws-ebs-csi-driver"
  service_account_role_arn = aws_iam_role.ebs_csi.arn
  # Let AWS choose the latest compatible version for EKS 1.32
  resolve_conflicts_on_update = "PRESERVE"

  tags = merge(local.common_tags, {
    Name = "${local.cluster_name}-ebs-csi-driver"
  })

  depends_on = [
    aws_iam_role_policy_attachment.ebs_csi
  ]
}

