# ============================================================================
# CLOUDWATCH OBSERVABILITY ADDON
# Container Insights — node, pod, and container metrics in CloudWatch.
# ============================================================================

# ── IRSA ─────────────────────────────────────────────────────────────────────

data "aws_iam_policy_document" "cloudwatch_observability_assume_role" {
  count = var.enable_cloudwatch_observability ? 1 : 0

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
      values   = ["system:serviceaccount:amazon-cloudwatch:cloudwatch-agent"]
    }
    condition {
      test     = "StringEquals"
      variable = "${local.oidc_provider_url}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "cloudwatch_observability" {
  count = var.enable_cloudwatch_observability ? 1 : 0

  name               = "${var.project_name}-${var.environment}-cloudwatch-observability"
  assume_role_policy = data.aws_iam_policy_document.cloudwatch_observability_assume_role[0].json

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-cloudwatch-observability"
  })
}

resource "aws_iam_role_policy_attachment" "cloudwatch_agent_server_policy" {
  count = var.enable_cloudwatch_observability ? 1 : 0

  role       = aws_iam_role.cloudwatch_observability[0].name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

data "aws_iam_policy_document" "cloudwatch_container_insights" {
  count = var.enable_cloudwatch_observability ? 1 : 0

  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams",
      "logs:DescribeLogGroups",
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "cloudwatch:PutMetricData",
      "ec2:DescribeVolumes",
      "ec2:DescribeTags",
      "ec2:DescribeInstances",
      "ec2:DescribeInstanceStatus",
      "eks:DescribeCluster",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "cloudwatch_container_insights" {
  count = var.enable_cloudwatch_observability ? 1 : 0

  name        = "${var.project_name}-${var.environment}-cloudwatch-container-insights"
  description = "CloudWatch Container Insights — metrics and logs"
  policy      = data.aws_iam_policy_document.cloudwatch_container_insights[0].json

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-cloudwatch-container-insights"
  })
}

resource "aws_iam_role_policy_attachment" "cloudwatch_container_insights" {
  count = var.enable_cloudwatch_observability ? 1 : 0

  role       = aws_iam_role.cloudwatch_observability[0].name
  policy_arn = aws_iam_policy.cloudwatch_container_insights[0].arn
}

# ── EKS MANAGED ADDON ────────────────────────────────────────────────────────

resource "aws_eks_addon" "cloudwatch_observability" {
  count = var.enable_cloudwatch_observability ? 1 : 0

  cluster_name                = local.cluster_name
  addon_name                  = "amazon-cloudwatch-observability"
  addon_version               = "v1.5.1-eksbuild.1"
  service_account_role_arn    = aws_iam_role.cloudwatch_observability[0].arn
  resolve_conflicts_on_update = "PRESERVE"

  tags = merge(local.common_tags, {
    Name = "${local.cluster_name}-cloudwatch-observability"
  })

  depends_on = [
    aws_iam_role_policy_attachment.cloudwatch_agent_server_policy,
    aws_iam_role_policy_attachment.cloudwatch_container_insights,
  ]
}
