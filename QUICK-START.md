# Quick Start Guide

## 🚀 Interactive Deployment Script

The `run.sh` script handles **folders 1-5** (not Jenkins folder 6).

---

## 📋 Menu Options

```
1) Apply Infrastructure (Folders 1 & 2) - asks dev/prod tfvars
2) Destroy Infrastructure (Folders 2 & 1) - reverse order
3) Build Docker Images & Update Folder 4 - creates ECR images
4) Install Kubernetes & Monitoring (Folders 4 & 5)
5) Delete Monitoring & Kubernetes (Folders 5 & 4) - reverse order
6) Show Outputs (All folders)
7) Exit
```

---

## 🎯 What Each Option Does

### Option 1: Apply Infrastructure
- **Asks**: Which tfvars? (dev.tfvars or prod.tfvars)
- **Deploys**: Folder 1 (VPC, EKS) → Folder 2 (Addons)
- **Output**: EKS cluster ready

### Option 2: Destroy Infrastructure
- **Asks**: Type 'destroy' to confirm, then which tfvars was used?
- **Destroys**: Folder 2 (Addons) → Folder 1 (Infrastructure)
- **Output**: Cluster deleted

### Option 3: Build Docker Images
- **Asks**: Which environment? (dev or prod)
- **Builds**: All 10 services (9 backend + 1 frontend)
- **Pushes**: To ECR with git commit hash as tag
- **Updates**: Folder 4 manifests automatically
- **Output**: Images in ECR, manifests updated

### Option 4: Install Kubernetes & Monitoring
- **Deploys**: Folder 4 (namespace, database, redis, backend, frontend, ingresses)
- **Deploys**: Folder 5 (monitoring stack)
- **Output**: Application running with monitoring

### Option 5: Delete Monitoring & Kubernetes
- **Asks**: Confirm deletion
- **Deletes**: Folder 5 (monitoring) → Folder 4 (kubernetes)
- **Output**: Apps deleted, infrastructure still running

### Option 6: Show Outputs
- **Shows**: Terraform outputs, K8s resources, monitoring, frontend URL
- **Output**: Status of all deployments

---

## 🔄 Complete Deployment Flow

```bash
# Step 1: Apply Infrastructure
./run.sh → 1 → dev.tfvars → yes

# Step 2: Build Docker Images
./run.sh → 3 → dev → (builds & updates folder 4)

# Step 3: Install Kubernetes & Monitoring
./run.sh → 4 → (deploys folders 4 & 5)

# Step 4: Check Status
./run.sh → 6 → (shows all outputs)
```

---

## 🗑️ Complete Cleanup Flow

```bash
# Step 1: Delete Apps & Monitoring
./run.sh → 5 → yes → (deletes folders 5 & 4)

# Step 2: Destroy Infrastructure
./run.sh → 2 → destroy → dev.tfvars → (deletes folders 2 & 1)
```

---

## 📂 Folder Structure

```
1-infrastructure/     → VPC, EKS cluster, nodes
2-eks-addons/        → ALB controller, monitoring, autoscaling
3-application/       → Source code + Dockerfiles
4-kubernetes-manifests/ → K8s YAML files
5-monitoring/        → Monitoring stack (Prometheus, Grafana)
6-jenkins-pipelines/ → Jenkins CI/CD (separate from run.sh)
```

---

## ⚡ Key Features

✅ **Interactive**: Menu-driven, no command-line arguments
✅ **Smart**: Auto-detects Dockerfiles, auto-updates manifests
✅ **Safe**: Confirmation prompts, correct order (apply/destroy)
✅ **Flexible**: Choose dev/prod at runtime
✅ **Complete**: Handles infrastructure, apps, and monitoring

---

## 🎯 Prerequisites

```bash
# Required tools
- AWS CLI (configured with credentials)
- Terraform
- Docker
- kubectl
- Helm
- Git
```

---

## 📝 Quick Commands

```bash
# Make executable
chmod +x run.sh

# Run script
./run.sh

# Follow the menu!
```

---

**Simple, interactive, production-ready!** 🚀
