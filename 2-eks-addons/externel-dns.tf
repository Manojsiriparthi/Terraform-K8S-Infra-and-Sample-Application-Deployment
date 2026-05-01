# ============================================================================
# EXTERNAL DNS
# ============================================================================
# Automatically creates DNS records in Route53 for Kubernetes Ingresses
# When you create an Ingress with a hostname, External DNS creates the A record
# Requires: Route53 hosted zone
# ============================================================================

# ── IRSA for External DNS ────────────────────────────────────────────────────

data "aws_iam_policy_document" "external_dns_assume_role" {
  count = var.enable_external_dns ? 1 : 0

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
      values   = ["system:serviceaccount:kube-system:external-dns"]
    }
    condition {
      test     = "StringEquals"
      variable = "${local.oidc_provider_url}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "external_dns" {
  count = var.enable_external_dns ? 1 : 0

  name               = "${var.project_name}-${var.environment}-external-dns"
  assume_role_policy = data.aws_iam_policy_document.external_dns_assume_role[0].json

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-external-dns"
  })
}

# IAM policy for External DNS to manage Route53 records
data "aws_iam_policy_document" "external_dns_policy" {
  count = var.enable_external_dns ? 1 : 0

  statement {
    effect = "Allow"
    actions = [
      "route53:ChangeResourceRecordSets",
    ]
    resources = ["arn:aws:route53:::hostedzone/*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "route53:ListHostedZones",
      "route53:ListResourceRecordSets",
      "route53:ListTagsForResource",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "external_dns" {
  count = var.enable_external_dns ? 1 : 0

  name        = "${var.project_name}-${var.environment}-external-dns"
  description = "External DNS - Route53 record management"
  policy      = data.aws_iam_policy_document.external_dns_policy[0].json

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-external-dns"
  })
}

resource "aws_iam_role_policy_attachment" "external_dns" {
  count = var.enable_external_dns ? 1 : 0

  role       = aws_iam_role.external_dns[0].name
  policy_arn = aws_iam_policy.external_dns[0].arn
}

# ── HELM RELEASE ──────────────────────────────────────────────────────────────

resource "helm_release" "external_dns" {
  count = var.enable_external_dns ? 1 : 0

  name       = "external-dns"
  repository = "https://kubernetes-sigs.github.io/external-dns/"
  chart      = "external-dns"
  namespace  = "kube-system"
  version    = "1.15.0"

  values = [
    yamlencode({
      serviceAccount = {
        create = true
        name   = "external-dns"
        annotations = {
          "eks.amazonaws.com/role-arn" = aws_iam_role.external_dns[0].arn
        }
      }

      provider = "aws"

      # AWS specific settings
      aws = {
        region = var.aws_region
      }

      # Domain filter - only manage records in these domains
      # domainFilters = ["example.com"]  # Uncomment and set your domain

      # Policy - upsert-only (safer) or sync (can delete records)
      policy = "upsert-only"

      # Sources - what Kubernetes resources to watch
      sources = [
        "ingress",
        "service",
      ]

      # Ingress class filter - only manage ingresses with these classes
      # ingressClassFilters = ["alb-external"]

      # TXT registry - creates TXT records to track ownership
      txtOwnerId = local.cluster_name
      txtPrefix  = "external-dns-"

      # Logging
      logLevel  = "info"
      logFormat = "json"

      # Sync interval
      interval = "1m"

      # Resources
      resources = {
        requests = { cpu = "50m", memory = "64Mi" }
        limits   = { cpu = "100m", memory = "128Mi" }
      }

      nodeSelector = { "node-type" = "general" }

      priorityClassName = "system-cluster-critical"
    })
  ]

  depends_on = [aws_iam_role_policy_attachment.external_dns]
}

