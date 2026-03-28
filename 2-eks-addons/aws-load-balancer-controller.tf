# ============================================================================
# AWS LOAD BALANCER CONTROLLER IAM ROLE
# ============================================================================

data "aws_iam_policy_document" "aws_lb_controller_assume_role" {
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
      values   = ["system:serviceaccount:kube-system:aws-load-balancer-controller"]
    }
    condition {
      test     = "StringEquals"
      variable = "${local.oidc_provider_url}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "aws_lb_controller" {
  name               = "${var.project_name}-${var.environment}-aws-lb-controller"
  assume_role_policy = data.aws_iam_policy_document.aws_lb_controller_assume_role.json

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-aws-lb-controller"
  })
}

resource "aws_iam_policy" "aws_lb_controller" {
  name        = "${var.project_name}-${var.environment}-aws-lb-controller"
  description = "Policy for AWS Load Balancer Controller"
  policy      = file("${path.module}/policies/aws-lb-controller-policy.json")

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-aws-lb-controller"
  })
}

resource "aws_iam_role_policy_attachment" "aws_lb_controller" {
  role       = aws_iam_role.aws_lb_controller.name
  policy_arn = aws_iam_policy.aws_lb_controller.arn
}

# ============================================================================
# AWS LOAD BALANCER CONTROLLER DEPLOYMENT
# ============================================================================

resource "helm_release" "aws_lb_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  version    = "1.10.0"

  set {
    name  = "clusterName"
    value = local.cluster_name
  }

  set {
    name  = "serviceAccount.create"
    value = "true"
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.aws_lb_controller.arn
  }

  depends_on = [aws_iam_role_policy_attachment.aws_lb_controller]
}
