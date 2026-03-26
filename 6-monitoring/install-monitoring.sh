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
  --wait

# Install Kibana
echo "Installing Kibana..."
helm upgrade --install kibana elastic/kibana \
  --namespace monitoring \
  --values kibana-values.yaml \
  --wait

echo ""
echo "=========================================="
echo "Monitoring Stack Installed!"
echo "=========================================="
echo ""
echo "Access Grafana:"
echo "  kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80"
echo "  http://localhost:3000 (admin/changeme123)"
echo ""
echo "Access Kibana:"
echo "  kubectl get svc -n monitoring kibana-kibana"
echo "  Use LoadBalancer URL or port-forward"
echo ""
echo "View logs in CloudWatch:"
echo "  AWS Console → CloudWatch → Log Groups"
echo ""
echo "View logs in Kibana:"
echo "  Kibana → Discover → Create index pattern: eks-application-*"
echo ""
