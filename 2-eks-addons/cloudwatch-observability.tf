# ============================================================================
# CLOUDWATCH OBSERVABILITY ADDON
# Container Insights for EKS cluster monitoring
# ============================================================================

# IAM Policy for CloudWatch Observability
data "aws_iam_policy_document" "cloudwatch_observability_assume_role" {
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
  name               = "${var.project_name}-${var.environment}-cloudwatch-observability"
  assume_role_policy = data.aws_iam_policy_document.cloudwatch_observability_assume_role.json

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-cloudwatch-observability"
  })
}

# Attach CloudWatch Agent Server Policy
resource "aws_iam_role_policy_attachment" "cloudwatch_agent_server_policy" {
  role       = aws_iam_role.cloudwatch_observability.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Custom policy for Container Insights
data "aws_iam_policy_document" "cloudwatch_container_insights" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams",
      "logs:DescribeLogGroups"
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
      "ec2:DescribeInstanceStatus"
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "eks:DescribeCluster"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "cloudwatch_container_insights" {
  name        = "${var.project_name}-${var.environment}-cloudwatch-container-insights"
  description = "Policy for CloudWatch Container Insights"
  policy      = data.aws_iam_policy_document.cloudwatch_container_insights.json

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-cloudwatch-container-insights"
  })
}

resource "aws_iam_role_policy_attachment" "cloudwatch_container_insights" {
  role       = aws_iam_role.cloudwatch_observability.name
  policy_arn = aws_iam_policy.cloudwatch_container_insights.arn
}

# ============================================================================
# CLOUDWATCH OBSERVABILITY EKS ADDON
# ============================================================================

resource "aws_eks_addon" "cloudwatch_observability" {
  cluster_name             = local.cluster_name
  addon_name               = "amazon-cloudwatch-observability"
  addon_version            = "v1.5.1-eksbuild.1"
  service_account_role_arn = aws_iam_role.cloudwatch_observability.arn
  resolve_conflicts_on_update = "PRESERVE"

  tags = merge(local.common_tags, {
    Name = "${local.cluster_name}-cloudwatch-observability"
  })

  depends_on = [
    aws_iam_role_policy_attachment.cloudwatch_agent_server_policy,
    aws_iam_role_policy_attachment.cloudwatch_container_insights
  ]
}
