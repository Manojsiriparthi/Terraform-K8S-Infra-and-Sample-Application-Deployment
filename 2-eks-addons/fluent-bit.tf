# ============================================================================
# FLUENT BIT - LOG FORWARDING
# ============================================================================
# Fluent Bit collects logs from containers and forwards them to CloudWatch
# Lightweight alternative to Fluentd - uses less memory and CPU
# ============================================================================

# ── IRSA for Fluent Bit ──────────────────────────────────────────────────────

data "aws_iam_policy_document" "fluent_bit_assume_role" {
  count = var.enable_fluent_bit ? 1 : 0

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
      values   = ["system:serviceaccount:amazon-cloudwatch:fluent-bit"]
    }
    condition {
      test     = "StringEquals"
      variable = "${local.oidc_provider_url}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "fluent_bit" {
  count = var.enable_fluent_bit ? 1 : 0

  name               = "${var.project_name}-${var.environment}-fluent-bit"
  assume_role_policy = data.aws_iam_policy_document.fluent_bit_assume_role[0].json

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-fluent-bit"
  })
}

# IAM policy for Fluent Bit to write logs to CloudWatch
data "aws_iam_policy_document" "fluent_bit_policy" {
  count = var.enable_fluent_bit ? 1 : 0

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
}

resource "aws_iam_policy" "fluent_bit" {
  count = var.enable_fluent_bit ? 1 : 0

  name        = "${var.project_name}-${var.environment}-fluent-bit"
  description = "Fluent Bit - CloudWatch Logs write permissions"
  policy      = data.aws_iam_policy_document.fluent_bit_policy[0].json

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-fluent-bit"
  })
}

resource "aws_iam_role_policy_attachment" "fluent_bit" {
  count = var.enable_fluent_bit ? 1 : 0

  role       = aws_iam_role.fluent_bit[0].name
  policy_arn = aws_iam_policy.fluent_bit[0].arn
}

# ── HELM RELEASE ──────────────────────────────────────────────────────────────

resource "helm_release" "fluent_bit" {
  count = var.enable_fluent_bit ? 1 : 0

  name       = "fluent-bit"
  repository = "https://fluent.github.io/helm-charts"
  chart      = "fluent-bit"
  namespace  = "amazon-cloudwatch"
  version    = "0.47.10"

  create_namespace = true

  values = [
    yamlencode({
      serviceAccount = {
        create = true
        name   = "fluent-bit"
        annotations = {
          "eks.amazonaws.com/role-arn" = aws_iam_role.fluent_bit[0].arn
        }
      }

      # Use string-based config instead of structured
      config = {
        outputs = "[OUTPUT]\n    Name cloudwatch_logs\n    Match *\n    region ${var.aws_region}\n    log_group_name /aws/eks/${local.cluster_name}/application\n    log_stream_prefix fluent-bit-\n    auto_create_group true\n"
      }

      resources = {
        requests = { cpu = "100m", memory = "128Mi" }
        limits   = { cpu = "200m", memory = "256Mi" }
      }

      tolerations = [
        {
          operator = "Exists"
          effect   = "NoSchedule"
        }
      ]

      nodeSelector = {}

      priorityClassName = "system-node-critical"
    })
  ]

  depends_on = [aws_iam_role_policy_attachment.fluent_bit]
}

