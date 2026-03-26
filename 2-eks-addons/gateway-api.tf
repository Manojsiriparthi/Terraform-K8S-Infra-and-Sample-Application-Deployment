# ============================================================================
# KUBERNETES GATEWAY API
# Modern replacement for Ingress with better traffic management
# ============================================================================

# Install Gateway API CRDs
resource "helm_release" "gateway_api" {
  name       = "gateway-api"
  repository = "https://kubernetes-sigs.github.io/gateway-api"
  chart      = "gateway-api"
  namespace  = "gateway-system"
  version    = "1.2.0"

  create_namespace = true

  set {
    name  = "crds.install"
    value = "true"
  }

  depends_on = [
    data.aws_eks_cluster.cluster,
    helm_release.aws_load_balancer_controller
  ]
}

# Gateway Class for AWS Load Balancer Controller
resource "kubectl_manifest" "gateway_class" {
  yaml_body = <<-YAML
    apiVersion: gateway.networking.k8s.io/v1
    kind: GatewayClass
    metadata:
      name: aws-alb
    spec:
      controllerName: eks.amazonaws.com/alb
      description: AWS Application Load Balancer Gateway Class
  YAML

  depends_on = [helm_release.gateway_api]
}

# Public Gateway (internet-facing) - Frontend Only
resource "kubectl_manifest" "public_gateway" {
  yaml_body = <<-YAML
    apiVersion: gateway.networking.k8s.io/v1
    kind: Gateway
    metadata:
      name: public-gateway
      namespace: application
      annotations:
        alb.ingress.kubernetes.io/scheme: internet-facing
        alb.ingress.kubernetes.io/target-type: ip
        alb.ingress.kubernetes.io/healthcheck-path: /
    spec:
      gatewayClassName: aws-alb
      listeners:
      - name: http
        protocol: HTTP
        port: 80
        allowedRoutes:
          namespaces:
            from: Same
  YAML

  depends_on = [kubectl_manifest.gateway_class]
}

# Monitoring Gateway (internal) - Grafana & Kibana for DevOps Team
resource "kubectl_manifest" "monitoring_gateway" {
  yaml_body = <<-YAML
    apiVersion: gateway.networking.k8s.io/v1
    kind: Gateway
    metadata:
      name: monitoring-gateway
      namespace: monitoring
      annotations:
        alb.ingress.kubernetes.io/scheme: internal
        alb.ingress.kubernetes.io/target-type: ip
        alb.ingress.kubernetes.io/healthcheck-path: /
    spec:
      gatewayClassName: aws-alb
      listeners:
      - name: http
        protocol: HTTP
        port: 80
        allowedRoutes:
          namespaces:
            from: Same
  YAML

  depends_on = [kubectl_manifest.gateway_class]
}


