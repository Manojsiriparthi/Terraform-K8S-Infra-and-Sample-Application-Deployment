# ============================================================================
# CONSOLIDATED OUTPUTS - ALL EKS ADDONS
# ============================================================================
# Complete outputs for all deployed resources in 2-eks-addons
# Only references resources that actually exist in the configuration
# ============================================================================

# ── CLUSTER INFORMATION ──────────────────────────────────────────────────────

output "cluster_name" {
  description = "EKS cluster name"
  value       = local.cluster_name
}

output "cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = local.cluster_endpoint
}

output "cluster_region" {
  description = "AWS region"
  value       = var.aws_region
}

# ── OIDC PROVIDER ────────────────────────────────────────────────────────────

output "oidc_provider_arn" {
  description = "OIDC provider ARN for IRSA"
  value       = local.oidc_provider_arn
}

output "oidc_provider_url" {
  description = "OIDC provider URL"
  value       = local.oidc_provider_url
}

# ── VPC INFORMATION ──────────────────────────────────────────────────────────

output "vpc_id" {
  description = "VPC ID"
  value       = local.vpc_id
}

# ── CORE EKS ADDONS ──────────────────────────────────────────────────────────

output "core_addons" {
  description = "Core EKS managed addons versions"
  value = {
    vpc_cni      = aws_eks_addon.vpc_cni.addon_version
    kube_proxy   = aws_eks_addon.kube_proxy.addon_version
    coredns      = aws_eks_addon.coredns.addon_version
    pod_identity = aws_eks_addon.pod_identity.addon_version
  }
}

# ── CLOUDWATCH OBSERVABILITY ─────────────────────────────────────────────────

output "cloudwatch_observability" {
  description = "CloudWatch Observability addon details"
  value = var.enable_cloudwatch_observability ? {
    addon_version = aws_eks_addon.cloudwatch_observability.addon_version
    role_arn      = aws_iam_role.cloudwatch_observability.arn
    role_name     = aws_iam_role.cloudwatch_observability.name
  } : null
}

# ── AWS LOAD BALANCER CONTROLLER ─────────────────────────────────────────────

output "aws_load_balancer_controller" {
  description = "AWS Load Balancer Controller details"
  value = var.enable_aws_load_balancer_controller ? {
    role_arn               = aws_iam_role.aws_lb_controller.arn
    role_name              = aws_iam_role.aws_lb_controller.name
    helm_release_name      = helm_release.aws_lb_controller.name
    helm_version           = helm_release.aws_lb_controller.version
    ingress_class_external = kubernetes_ingress_class_v1.alb_external.metadata[0].name
    ingress_class_internal = kubernetes_ingress_class_v1.alb_internal.metadata[0].name
  } : null
}

# ── METRICS SERVER ───────────────────────────────────────────────────────────

output "metrics_server" {
  description = "Metrics Server details"
  value = var.enable_metrics_server ? {
    helm_release_name = helm_release.metrics_server[0].name
    helm_version      = helm_release.metrics_server[0].version
    enabled           = true
  } : {
    enabled = false
  }
}

# ── VERTICAL POD AUTOSCALER ──────────────────────────────────────────────────

output "vpa" {
  description = "Vertical Pod Autoscaler details"
  value = var.enable_vpa ? {
    helm_release_name = helm_release.vpa[0].name
    helm_version      = helm_release.vpa[0].version
    enabled           = true
  } : {
    enabled = false
  }
}

# ── KARPENTER ────────────────────────────────────────────────────────────────

output "karpenter" {
  description = "Karpenter autoscaler details"
  value = var.enable_karpenter ? {
    role_arn          = aws_iam_role.karpenter[0].arn
    role_name         = aws_iam_role.karpenter[0].name
    helm_release_name = helm_release.karpenter[0].name
    helm_version      = helm_release.karpenter[0].version
    enabled           = true
  } : {
    enabled = false
  }
}

# ── GATEWAY API ──────────────────────────────────────────────────────────────

output "gateway_api" {
  description = "Gateway API CRDs details"
  value = var.enable_gateway_api ? {
    helm_release_name = helm_release.gateway_api_crds[0].name
    helm_version      = helm_release.gateway_api_crds[0].version
    enabled           = true
  } : {
    enabled = false
  }
}

# ── DEPLOYMENT SUMMARY ───────────────────────────────────────────────────────

output "deployment_summary" {
  description = "Summary of all deployed addons"
  value = {
    cluster_name = local.cluster_name
    region       = var.aws_region
    
    core_addons = {
      vpc_cni      = "deployed"
      kube_proxy   = "deployed"
      coredns      = "deployed"
      pod_identity = "deployed"
    }
    
    observability = {
      cloudwatch = var.enable_cloudwatch_observability ? "deployed" : "disabled"
    }
    
    networking = {
      aws_load_balancer_controller = var.enable_aws_load_balancer_controller ? "deployed" : "disabled"
      ingress_classes              = var.enable_aws_load_balancer_controller ? ["alb-external", "alb-internal"] : []
    }
    
    optional_addons = {
      metrics_server = var.enable_metrics_server ? "deployed" : "disabled"
      vpa            = var.enable_vpa ? "deployed" : "disabled"
      karpenter      = var.enable_karpenter ? "deployed" : "disabled"
      gateway_api    = var.enable_gateway_api ? "deployed" : "disabled"
    }
  }
}
