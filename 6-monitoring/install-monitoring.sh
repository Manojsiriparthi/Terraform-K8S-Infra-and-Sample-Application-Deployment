#!/bin/bash

set -e

echo "Installing Monitoring Stack..."

# Add Helm repositories
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add elastic https://helm.elastic.co
helm repo update

# Create monitoring namespace
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -

# Install Prometheus Stack (Prometheus + Grafana + Alertmanager)
echo "Installing Prometheus Stack..."
helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --values prometheus-values.yaml \
  --wait

# Install Elasticsearch
echo "Installing Elasticsearch..."
helm upgrade --install elasticsearch elastic/elasticsearch \
  --namespace monitoring \
  --values elasticsearch-values.yaml \
  --timeout 10m \
  --wait

# Install Kibana (using simple deployment instead of Helm)
echo "Installing Kibana..."

# Aggressive cleanup of any leftover Kibana resources
echo "Cleaning up any existing Kibana resources..."

# Uninstall existing Kibana helm release first
helm uninstall kibana -n monitoring 2>/dev/null || true
sleep 5

# Delete all Kibana Kubernetes resources
kubectl delete deployment kibana -n monitoring --ignore-not-found=true
kubectl delete deployment kibana-kibana -n monitoring --ignore-not-found=true
kubectl delete statefulset kibana-kibana -n monitoring --ignore-not-found=true
kubectl delete service kibana-kibana -n monitoring --ignore-not-found=true
kubectl delete role pre-install-kibana-kibana -n monitoring --ignore-not-found=true
kubectl delete role post-delete-kibana-kibana -n monitoring --ignore-not-found=true
kubectl delete rolebinding pre-install-kibana-kibana -n monitoring --ignore-not-found=true
kubectl delete rolebinding post-delete-kibana-kibana -n monitoring --ignore-not-found=true
kubectl delete serviceaccount pre-install-kibana-kibana -n monitoring --ignore-not-found=true
kubectl delete serviceaccount post-delete-kibana-kibana -n monitoring --ignore-not-found=true
kubectl delete job -n monitoring -l app=kibana --ignore-not-found=true
kubectl delete pod -n monitoring -l app=kibana --ignore-not-found=true
kubectl delete secret -n monitoring -l app=kibana --ignore-not-found=true

# Delete configmaps explicitly
kubectl delete configmap kibana-kibana-helm-scripts -n monitoring --ignore-not-found=true
kubectl delete configmap -n monitoring -l app=kibana --ignore-not-found=true

# Wait for cleanup to complete
echo "Waiting for cleanup to complete..."
sleep 15

echo "Deploying Kibana using Kubernetes manifests (no Helm)..."
kubectl apply -f kibana-deployment.yaml

echo "Waiting for Kibana to be ready..."
kubectl wait --for=condition=available deployment/kibana -n monitoring --timeout=300s || true

echo ""
echo "=========================================="
echo "Monitoring Stack Installed!"
echo "=========================================="
echo ""

# Check pod status
echo "Checking pod status..."
kubectl get pods -n monitoring

echo ""
echo "=========================================="
echo "Access Information"
echo "=========================================="
echo ""
echo "Access Grafana:"
echo "  kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80"
echo "  http://localhost:3000 (admin/changeme123)"
echo ""
echo "Access Kibana via Ingress:"
echo "  After deploying monitoring-ingress.yaml:"
echo "  http://<internal-alb-url>/kibana"
echo ""
echo "Or port-forward directly:"
echo "  kubectl port-forward -n monitoring svc/kibana-kibana 5601:5601"
echo "  http://localhost:5601/kibana"
echo ""
echo "View logs in CloudWatch:"
echo "  AWS Console → CloudWatch → Log Groups"
echo ""
echo "Verify Elasticsearch connection:"
echo "  kubectl exec -n monitoring -it \$(kubectl get pod -n monitoring -l app=kibana -o jsonpath='{.items[0].metadata.name}') -- curl http://elasticsearch-master:9200"
echo ""
