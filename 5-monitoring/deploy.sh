#!/usr/bin/env bash
# ==============================================================================
# ShopEase Monitoring Stack — Deploy Script
# ==============================================================================
# Usage:
#   ./deploy.sh              # install / upgrade with all defaults
#   ./deploy.sh --dry-run    # preview what would be applied
#   ./deploy.sh --uninstall  # remove the monitoring stack
#
# Prerequisites:
#   - kubectl configured and pointing to the correct cluster
#   - helm >= 3.12 installed
#   - AWS Load Balancer Controller already running in kube-system
#   - ebs-gp3 StorageClass available
# ==============================================================================

set -euo pipefail

RELEASE_NAME="monitoring"
NAMESPACE="monitoring"
CHART_DIR="$(cd "$(dirname "$0")/helm" && pwd)"
VALUES_DIR="$(cd "$(dirname "$0")/values" && pwd)"

# Colours
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log()  { echo -e "${GREEN}[INFO]${NC}  $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC}  $*"; }
err()  { echo -e "${RED}[ERROR]${NC} $*" >&2; exit 1; }

# ------------------------------------------------------------------------------
# Parse arguments
# ------------------------------------------------------------------------------
DRY_RUN=""
UNINSTALL=false

for arg in "$@"; do
  case $arg in
    --dry-run)   DRY_RUN="--dry-run" ;;
    --uninstall) UNINSTALL=true ;;
    *) warn "Unknown argument: $arg" ;;
  esac
done

# ------------------------------------------------------------------------------
# Uninstall
# ------------------------------------------------------------------------------
if [ "$UNINSTALL" = true ]; then
  warn "Uninstalling monitoring stack..."
  helm uninstall "$RELEASE_NAME" -n "$NAMESPACE" || true
  log "Done. PVCs are NOT deleted automatically — remove manually if needed."
  exit 0
fi

# ------------------------------------------------------------------------------
# Pre-flight checks
# ------------------------------------------------------------------------------
log "Running pre-flight checks..."

command -v helm    >/dev/null 2>&1 || err "helm not found. Install helm >= 3.12"
command -v kubectl >/dev/null 2>&1 || err "kubectl not found"

HELM_VERSION=$(helm version --short | grep -oP 'v\K[0-9]+' | head -1)
[ "$HELM_VERSION" -ge 3 ] || err "Helm 3+ required"

kubectl cluster-info >/dev/null 2>&1 || err "kubectl cannot reach the cluster"

# Check AWS LB Controller is running
if ! kubectl get deployment aws-load-balancer-controller -n kube-system >/dev/null 2>&1; then
  warn "AWS Load Balancer Controller not found in kube-system — ingress may not work"
fi

# Check StorageClass
if ! kubectl get storageclass ebs-gp3 >/dev/null 2>&1; then
  warn "StorageClass 'ebs-gp3' not found — PVCs will fail. Ensure EBS CSI driver is installed."
fi

# ------------------------------------------------------------------------------
# Add / update Helm repos
# ------------------------------------------------------------------------------
log "Adding Helm repositories..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts 2>/dev/null || true
helm repo add elastic              https://helm.elastic.co                            2>/dev/null || true
helm repo update

# ------------------------------------------------------------------------------
# Update chart dependencies
# ------------------------------------------------------------------------------
log "Updating chart dependencies..."
helm dependency update "$CHART_DIR"

# ------------------------------------------------------------------------------
# Deploy
# ------------------------------------------------------------------------------
log "Deploying monitoring stack (release: $RELEASE_NAME, namespace: $NAMESPACE)..."

helm upgrade --install "$RELEASE_NAME" "$CHART_DIR" \
  --namespace "$NAMESPACE" \
  --create-namespace \
  --values "$VALUES_DIR/prometheus-values.yaml" \
  --values "$VALUES_DIR/grafana-values.yaml" \
  --values "$VALUES_DIR/elasticsearch-values.yaml" \
  --values "$VALUES_DIR/kibana-values.yaml" \
  --timeout 15m \
  --wait \
  --atomic \
  ${DRY_RUN}

# ------------------------------------------------------------------------------
# Post-deploy summary
# ------------------------------------------------------------------------------
if [ -z "$DRY_RUN" ]; then
  log "Monitoring stack deployed successfully!"
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  Pod status"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  kubectl get pods -n "$NAMESPACE"

  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  Internal ALB DNS (shared with backend)"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  ALB_DNS=$(kubectl get ingress monitoring-ingress -n "$NAMESPACE" \
    -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "<pending>")
  echo "  ALB: http://$ALB_DNS"
  echo ""
  echo "  Grafana      → http://$ALB_DNS/grafana"
  echo "  Prometheus   → http://$ALB_DNS/prometheus"
  echo "  Alertmanager → http://$ALB_DNS/alertmanager"
  echo "  Kibana       → http://$ALB_DNS/kibana"
  echo ""
  echo "  Grafana credentials: admin / (set via --set or CI/CD secret)"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
fi
