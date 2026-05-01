# ============================================================================
# AWS LOAD BALANCER CONTROLLER
# ============================================================================
# Manages AWS ALB/NLB from Kubernetes Ingress and Service resources.
#
# ALB strategy for this cluster:
#   External ALB (internet-facing):
#     - group.name: external-alb
#     - Path-based routing: /app1, /app2, /app3 ... → multiple apps, one ALB
#     - Example: alb.example.com/youtube, alb.example.com/netflix
#
#   Internal ALB (private):
#     - group.name: internal-alb
#     - Backend APIs + monitoring tools (Grafana, Prometheus, Kibana)
#     - Example: internal-alb/api, internal-alb/grafana, internal-alb/kibana
# ============================================================================

# ── IRSA ─────────────────────────────────────────────────────────────────────

data "aws_iam_policy_document" "aws_lb_controller_assume_role" {
  count = var.enable_aws_load_balancer_controller ? 1 : 0

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
  count = var.enable_aws_load_balancer_controller ? 1 : 0

  name               = "${var.project_name}-${var.environment}-aws-lb-controller"
  assume_role_policy = data.aws_iam_policy_document.aws_lb_controller_assume_role[0].json

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-aws-lb-controller"
  })
}

# Use inline policy instead of file
resource "aws_iam_policy" "aws_lb_controller" {
  count = var.enable_aws_load_balancer_controller ? 1 : 0

  name        = "${var.project_name}-${var.environment}-aws-lb-controller"
  description = "AWS Load Balancer Controller - full ALB/NLB management"
  
  # Inline policy - AWS Load Balancer Controller IAM Policy
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "iam:CreateServiceLinkedRole"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "iam:AWSServiceName" = "elasticloadbalancing.amazonaws.com"
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeAccountAttributes",
          "ec2:DescribeAddresses",
          "ec2:DescribeAvailabilityZones",
          "ec2:DescribeInternetGateways",
          "ec2:DescribeVpcs",
          "ec2:DescribeVpcPeeringConnections",
          "ec2:DescribeSubnets",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeInstances",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DescribeTags",
          "ec2:GetCoipPoolUsage",
          "ec2:DescribeCoipPools",
          "elasticloadbalancing:DescribeLoadBalancers",
          "elasticloadbalancing:DescribeLoadBalancerAttributes",
          "elasticloadbalancing:DescribeListeners",
          "elasticloadbalancing:DescribeListenerCertificates",
          "elasticloadbalancing:DescribeSSLPolicies",
          "elasticloadbalancing:DescribeRules",
          "elasticloadbalancing:DescribeTargetGroups",
          "elasticloadbalancing:DescribeTargetGroupAttributes",
          "elasticloadbalancing:DescribeTargetHealth",
          "elasticloadbalancing:DescribeTags"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "cognito-idp:DescribeUserPoolClient",
          "acm:ListCertificates",
          "acm:DescribeCertificate",
          "iam:ListServerCertificates",
          "iam:GetServerCertificate",
          "waf-regional:GetWebACL",
          "waf-regional:GetWebACLForResource",
          "waf-regional:AssociateWebACL",
          "waf-regional:DisassociateWebACL",
          "wafv2:GetWebACL",
          "wafv2:GetWebACLForResource",
          "wafv2:AssociateWebACL",
          "wafv2:DisassociateWebACL",
          "shield:GetSubscriptionState",
          "shield:DescribeProtection",
          "shield:CreateProtection",
          "shield:DeleteProtection"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:RevokeSecurityGroupIngress"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateSecurityGroup"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateTags"
        ]
        Resource = "arn:aws:ec2:*:*:security-group/*"
        Condition = {
          StringEquals = {
            "ec2:CreateAction" = "CreateSecurityGroup"
          }
          Null = {
            "aws:RequestTag/elbv2.k8s.aws/cluster" = "false"
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateTags",
          "ec2:DeleteTags"
        ]
        Resource = "arn:aws:ec2:*:*:security-group/*"
        Condition = {
          Null = {
            "aws:RequestTag/elbv2.k8s.aws/cluster"  = "true"
            "aws:ResourceTag/elbv2.k8s.aws/cluster" = "false"
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:RevokeSecurityGroupIngress",
          "ec2:DeleteSecurityGroup"
        ]
        Resource = "*"
        Condition = {
          Null = {
            "aws:ResourceTag/elbv2.k8s.aws/cluster" = "false"
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "elasticloadbalancing:CreateLoadBalancer",
          "elasticloadbalancing:CreateTargetGroup"
        ]
        Resource = "*"
        Condition = {
          Null = {
            "aws:RequestTag/elbv2.k8s.aws/cluster" = "false"
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "elasticloadbalancing:CreateListener",
          "elasticloadbalancing:DeleteListener",
          "elasticloadbalancing:CreateRule",
          "elasticloadbalancing:DeleteRule"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "elasticloadbalancing:AddTags",
          "elasticloadbalancing:RemoveTags"
        ]
        Resource = [
          "arn:aws:elasticloadbalancing:*:*:targetgroup/*/*",
          "arn:aws:elasticloadbalancing:*:*:loadbalancer/net/*/*",
          "arn:aws:elasticloadbalancing:*:*:loadbalancer/app/*/*"
        ]
        Condition = {
          Null = {
            "aws:RequestTag/elbv2.k8s.aws/cluster"  = "true"
            "aws:ResourceTag/elbv2.k8s.aws/cluster" = "false"
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "elasticloadbalancing:AddTags",
          "elasticloadbalancing:RemoveTags"
        ]
        Resource = [
          "arn:aws:elasticloadbalancing:*:*:listener/net/*/*/*",
          "arn:aws:elasticloadbalancing:*:*:listener/app/*/*/*",
          "arn:aws:elasticloadbalancing:*:*:listener-rule/net/*/*/*",
          "arn:aws:elasticloadbalancing:*:*:listener-rule/app/*/*/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "elasticloadbalancing:ModifyLoadBalancerAttributes",
          "elasticloadbalancing:SetIpAddressType",
          "elasticloadbalancing:SetSecurityGroups",
          "elasticloadbalancing:SetSubnets",
          "elasticloadbalancing:DeleteLoadBalancer",
          "elasticloadbalancing:ModifyTargetGroup",
          "elasticloadbalancing:ModifyTargetGroupAttributes",
          "elasticloadbalancing:DeleteTargetGroup"
        ]
        Resource = "*"
        Condition = {
          Null = {
            "aws:ResourceTag/elbv2.k8s.aws/cluster" = "false"
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "elasticloadbalancing:AddTags"
        ]
        Resource = [
          "arn:aws:elasticloadbalancing:*:*:targetgroup/*/*",
          "arn:aws:elasticloadbalancing:*:*:loadbalancer/net/*/*",
          "arn:aws:elasticloadbalancing:*:*:loadbalancer/app/*/*"
        ]
        Condition = {
          StringEquals = {
            "elasticloadbalancing:CreateAction" = [
              "CreateTargetGroup",
              "CreateLoadBalancer"
            ]
          }
          Null = {
            "aws:RequestTag/elbv2.k8s.aws/cluster" = "false"
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "elasticloadbalancing:RegisterTargets",
          "elasticloadbalancing:DeregisterTargets"
        ]
        Resource = "arn:aws:elasticloadbalancing:*:*:targetgroup/*/*"
      },
      {
        Effect = "Allow"
        Action = [
          "elasticloadbalancing:SetWebAcl",
          "elasticloadbalancing:ModifyListener",
          "elasticloadbalancing:AddListenerCertificates",
          "elasticloadbalancing:RemoveListenerCertificates",
          "elasticloadbalancing:ModifyRule"
        ]
        Resource = "*"
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-aws-lb-controller"
  })
}

resource "aws_iam_role_policy_attachment" "aws_lb_controller" {
  count = var.enable_aws_load_balancer_controller ? 1 : 0

  role       = aws_iam_role.aws_lb_controller[0].name
  policy_arn = aws_iam_policy.aws_lb_controller[0].arn
}

# ── HELM RELEASE ──────────────────────────────────────────────────────────────

resource "helm_release" "aws_lb_controller" {
  count = var.enable_aws_load_balancer_controller ? 1 : 0

  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  version    = "1.10.0"

  values = [
    yamlencode({
      clusterName = local.cluster_name
      region      = var.aws_region
      vpcId       = local.vpc_id  # required for target group binding

      serviceAccount = {
        create = true
        name   = "aws-load-balancer-controller"
        annotations = {
          "eks.amazonaws.com/role-arn" = aws_iam_role.aws_lb_controller[0].arn
        }
      }

      # HA — 2 replicas with leader election
      replicaCount = 2

      # Enable shield and WAF integration (optional — enable if using WAF)
      enableShield = false
      enableWaf    = false
      enableWafv2  = false

      resources = {
        requests = { cpu = "100m", memory = "128Mi" }
        limits   = { cpu = "200m", memory = "256Mi" }
      }

      # Spread across AZs
      topologySpreadConstraints = [
        {
          maxSkew           = 1
          topologyKey       = "topology.kubernetes.io/zone"
          whenUnsatisfiable = "DoNotSchedule"
          labelSelector = {
            matchLabels = {
              "app.kubernetes.io/name" = "aws-load-balancer-controller"
            }
          }
        }
      ]

      nodeSelector = { "node-type" = "general" }

      priorityClassName = "system-cluster-critical"
    })
  ]

  depends_on = [aws_iam_role_policy_attachment.aws_lb_controller]
}

# ── INGRESSCLASS — EXTERNAL ALB ───────────────────────────────────────────────
# Use in Ingress: ingressClassName: alb-external
# Annotation:    alb.ingress.kubernetes.io/scheme: internet-facing
# Group:         alb.ingress.kubernetes.io/group.name: external-alb
# Result:        ONE internet-facing ALB shared across all apps in the group
#                Path-based: /app1 → svc1, /app2 → svc2, /app3 → svc3

resource "kubernetes_ingress_class_v1" "alb_external" {
  count = var.enable_aws_load_balancer_controller ? 1 : 0

  metadata {
    name = "alb-external"
    annotations = {
      "ingressclass.kubernetes.io/is-default-class" = "false"
    }
  }

  spec {
    controller = "ingress.k8s.aws/alb"
  }

  depends_on = [helm_release.aws_lb_controller]
}

# ── INGRESSCLASS — INTERNAL ALB ───────────────────────────────────────────────
# Use in Ingress: ingressClassName: alb-internal
# Annotation:    alb.ingress.kubernetes.io/scheme: internal
# Group:         alb.ingress.kubernetes.io/group.name: internal-alb
# Result:        ONE internal ALB shared by backend APIs + monitoring tools

resource "kubernetes_ingress_class_v1" "alb_internal" {
  count = var.enable_aws_load_balancer_controller ? 1 : 0

  metadata {
    name = "alb-internal"
    annotations = {
      "ingressclass.kubernetes.io/is-default-class" = "false"
    }
  }

  spec {
    controller = "ingress.k8s.aws/alb"
  }

  depends_on = [helm_release.aws_lb_controller]
}
