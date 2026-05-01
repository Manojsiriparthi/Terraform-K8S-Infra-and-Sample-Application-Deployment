# ============================================================================
# GATEWAY API (Optional - AWS Load Balancer Controller already supports Ingress)
# ============================================================================
# Gateway API is the next-generation Ingress API for Kubernetes
# AWS Load Balancer Controller supports both Ingress and Gateway API
# 
# Note: This is OPTIONAL. Your current setup with Ingress + ALB Controller works fine.
# Only enable this if you want to use Gateway API instead of Ingress resources.
# ============================================================================

# Install Gateway API CRDs
resource "helm_release" "gateway_api_crds" {
  count = var.enable_gateway_api ? 1 : 0

  name       = "gateway-api-crds"
  repository = "https://gateway-api.github.io/gateway-api"
  chart      = "gateway-api-crds"
  namespace  = "gateway-system"
  version    = "v1.2.1"

  create_namespace = true

  set {
    name  = "installCRDs"
    value = "true"
  }

  tags = merge(local.common_tags, {
    Name = "${local.cluster_name}-gateway-api-crds"
  })
}

# Gateway API is already supported by AWS Load Balancer Controller
# No additional controller needed - just install CRDs above
# 
# To use Gateway API:
# 1. Install CRDs (above)
# 2. Create Gateway resource (in Kubernetes manifests)
# 3. Create HTTPRoute resources (instead of Ingress)
#
# Example Gateway:
# apiVersion: gateway.networking.k8s.io/v1
# kind: Gateway
# metadata:
#   name: frontend-gateway
#   annotations:
#     alb.ingress.kubernetes.io/scheme: internet-facing
# spec:
#   gatewayClassName: aws-alb
#   listeners:
#   - name: http
#     protocol: HTTP
#     port: 80
