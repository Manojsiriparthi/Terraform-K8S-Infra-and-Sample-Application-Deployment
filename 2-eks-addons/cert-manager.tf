# ============================================================================
# CERT MANAGER
# ============================================================================
# Automatically provisions and manages TLS certificates from Let's Encrypt
# Works with Ingress to automatically get HTTPS certificates
# Requires: Domain name and DNS validation (works with External DNS)
# ============================================================================

# ── IRSA for Cert Manager ────────────────────────────────────────────────────

data "aws_iam_policy_document" "cert_manager_assume_role" {
  count = var.enable_cert_manager ? 1 : 0

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
      values   = ["system:serviceaccount:cert-manager:cert-manager"]
    }
    condition {
      test     = "StringEquals"
      variable = "${local.oidc_provider_url}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "cert_manager" {
  count = var.enable_cert_manager ? 1 : 0

  name               = "${var.project_name}-${var.environment}-cert-manager"
  assume_role_policy = data.aws_iam_policy_document.cert_manager_assume_role[0].json

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-cert-manager"
  })
}

# IAM policy for Cert Manager to manage Route53 records (for DNS-01 challenge)
data "aws_iam_policy_document" "cert_manager_policy" {
  count = var.enable_cert_manager ? 1 : 0

  statement {
    effect = "Allow"
    actions = [
      "route53:GetChange",
    ]
    resources = ["arn:aws:route53:::change/*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "route53:ChangeResourceRecordSets",
      "route53:ListResourceRecordSets",
    ]
    resources = ["arn:aws:route53:::hostedzone/*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "route53:ListHostedZonesByName",
      "route53:ListHostedZones",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "cert_manager" {
  count = var.enable_cert_manager ? 1 : 0

  name        = "${var.project_name}-${var.environment}-cert-manager"
  description = "Cert Manager - Route53 DNS validation for Let's Encrypt"
  policy      = data.aws_iam_policy_document.cert_manager_policy[0].json

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-cert-manager"
  })
}

resource "aws_iam_role_policy_attachment" "cert_manager" {
  count = var.enable_cert_manager ? 1 : 0

  role       = aws_iam_role.cert_manager[0].name
  policy_arn = aws_iam_policy.cert_manager[0].arn
}

# ── HELM RELEASE ──────────────────────────────────────────────────────────────

resource "helm_release" "cert_manager" {
  count = var.enable_cert_manager ? 1 : 0

  name       = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  namespace  = "cert-manager"
  version    = "v1.16.2"

  create_namespace = true

  values = [
    yamlencode({
      # Install CRDs
      crds = {
        enabled = true
      }

      serviceAccount = {
        create = true
        name   = "cert-manager"
        annotations = {
          "eks.amazonaws.com/role-arn" = aws_iam_role.cert_manager[0].arn
        }
      }

      # Enable Prometheus metrics
      prometheus = {
        enabled = true
      }

      # Resources
      resources = {
        requests = { cpu = "50m", memory = "128Mi" }
        limits   = { cpu = "200m", memory = "256Mi" }
      }

      # Webhook resources
      webhook = {
        resources = {
          requests = { cpu = "50m", memory = "64Mi" }
          limits   = { cpu = "100m", memory = "128Mi" }
        }
      }

      # CA Injector resources
      cainjector = {
        resources = {
          requests = { cpu = "50m", memory = "128Mi" }
          limits   = { cpu = "200m", memory = "256Mi" }
        }
      }

      nodeSelector = { "node-type" = "general" }

      # priorityClassName not supported in this chart version
    })
  ]

  depends_on = [aws_iam_role_policy_attachment.cert_manager]
}

# ── CLUSTER ISSUER (Let's Encrypt) ───────────────────────────────────────────
# Creates a ClusterIssuer for Let's Encrypt production certificates
# Uncomment after you have a domain and External DNS configured

# resource "kubectl_manifest" "letsencrypt_prod" {
#   count = var.enable_cert_manager ? 1 : 0
#
#   yaml_body = <<-YAML
#     apiVersion: cert-manager.io/v1
#     kind: ClusterIssuer
#     metadata:
#       name: letsencrypt-prod
#     spec:
#       acme:
#         server: https://acme-v02.api.letsencrypt.org/directory
#         email: ${var.owner_email}
#         privateKeySecretRef:
#           name: letsencrypt-prod
#         solvers:
#           - dns01:
#               route53:
#                 region: ${var.aws_region}
#   YAML
#
#   depends_on = [helm_release.cert_manager]
# }

# ── USAGE EXAMPLE ────────────────────────────────────────────────────────────
# After enabling Cert Manager, add this annotation to your Ingress:
#
# apiVersion: networking.k8s.io/v1
# kind: Ingress
# metadata:
#   name: my-ingress
#   annotations:
#     cert-manager.io/cluster-issuer: "letsencrypt-prod"
# spec:
#   tls:
#     - hosts:
#         - myapp.example.com
#       secretName: myapp-tls
#   rules:
#     - host: myapp.example.com
#       http:
#         paths:
#           - path: /
#             pathType: Prefix
#             backend:
#               service:
#                 name: myapp
#                 port:
#                   number: 80

