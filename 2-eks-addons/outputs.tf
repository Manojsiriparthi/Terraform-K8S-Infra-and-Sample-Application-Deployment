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
  value = {
    addon_version = try(aws_eks_addon.cloudwatch_observability[0].addon_version, "not deployed")
    role_arn      = try(aws_iam_role.cloudwatch_observability[0].arn, "not deployed")
    role_name     = try(aws_iam_role.cloudwatch_observability[0].name, "not deployed")
    enabled       = var.enable_cloudwatch_observability
  }
}

# ── AWS LOAD BALANCER CONTROLLER ─────────────────────────────────────────────

output "aws_load_balancer_controller" {
  description = "AWS Load Balancer Controller details"
  value = {
    role_arn               = try(aws_iam_role.aws_lb_controller[0].arn, "not deployed")
    role_name              = try(aws_iam_role.aws_lb_controller[0].name, "not deployed")
    helm_release_name      = try(helm_release.aws_lb_controller[0].name, "not deployed")
    helm_version           = try(helm_release.aws_lb_controller[0].version, "not deployed")
    ingress_class_external = try(kubernetes_ingress_class_v1.alb_external[0].metadata[0].name, "not deployed")
    ingress_class_internal = try(kubernetes_ingress_class_v1.alb_internal[0].metadata[0].name, "not deployed")
    enabled                = var.enable_aws_load_balancer_controller
  }
}

# ── METRICS SERVER ───────────────────────────────────────────────────────────

output "metrics_server" {
  description = "Metrics Server details"
  value = {
    helm_release_name = try(helm_release.metrics_server[0].name, "not deployed")
    helm_version      = try(helm_release.metrics_server[0].version, "not deployed")
    enabled           = var.enable_metrics_server
  }
}

# ── VERTICAL POD AUTOSCALER ──────────────────────────────────────────────────

output "vpa" {
  description = "Vertical Pod Autoscaler details"
  value = {
    helm_release_name = try(helm_release.vpa[0].name, "not deployed")
    helm_version      = try(helm_release.vpa[0].version, "not deployed")
    enabled           = var.enable_vpa
  }
}

# ── KARPENTER ────────────────────────────────────────────────────────────────

output "karpenter" {
  description = "Karpenter autoscaler details"
  value = {
    role_arn          = try(aws_iam_role.karpenter[0].arn, "not deployed")
    role_name         = try(aws_iam_role.karpenter[0].name, "not deployed")
    helm_release_name = try(helm_release.karpenter[0].name, "not deployed")
    helm_version      = try(helm_release.karpenter[0].version, "not deployed")
    enabled           = var.enable_karpenter
  }
}

# ── GATEWAY API ──────────────────────────────────────────────────────────────

output "gateway_api" {
  description = "Gateway API CRDs details"
  value = {
    helm_release_name = try(helm_release.gateway_api_crds[0].name, "not deployed")
    helm_version      = try(helm_release.gateway_api_crds[0].version, "not deployed")
    enabled           = var.enable_gateway_api
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
