# Jenkins CI/CD Pipelines - Simplified

## 📁 Structure

```
6-jenkins-pipelines/
├── 1-infrastructure-pipeline.groovy    # Terraform (folders 1-2)
├── 2-application-pipeline.groovy       # Docker + K8s (folders 3-4)
└── README.md                           # This file
```

**No environment files needed!** All configuration is in Terraform files.

---

## 🔌 Required Jenkins Plugins

```bash
# Install these plugins in Jenkins
1. Pipeline (workflow-aggregator)
2. Git (git)
3. Docker Pipeline (docker-workflow)
4. Kubernetes CLI (kubernetes-cli)
5. AWS Credentials (aws-credentials)
6. Terraform (terraform)
7. Credentials Binding (credentials-binding)
```

### Install via Jenkins CLI:
```bash
jenkins-cli install-plugin workflow-aggregator git docker-workflow \
  kubernetes-cli aws-credentials terraform credentials-binding
```

---

## 🔐 Jenkins Credentials Setup

### Only 2 Types of Credentials Needed:

#### 1. AWS Credentials (Single credential for all environments)
```
Manage Jenkins → Credentials → Add Credentials

Kind: AWS Credentials
ID: aws-credentials
Description: AWS credentials for all environments
Access Key ID: <your-access-key>
Secret Access Key: <your-secret-key>
```

#### 2. Kubeconfig Files (One per environment)
```
Manage Jenkins → Credentials → Add Credentials

Kind: Secret file
ID: kubeconfig-dev
File: Upload kubeconfig for dev cluster

Kind: Secret file
ID: kubeconfig-qa
File: Upload kubeconfig for qa cluster

Kind: Secret file
ID: kubeconfig-prod
File: Upload kubeconfig for prod cluster
```

**That's it!** No other credentials or environment files needed.

---

## 📝 Where Configuration Lives

### ✅ Terraform Files (Infrastructure Config)
All infrastructure configuration is in Terraform files:

```
1-infrastructure/
├── dev.tfvars          # Dev: t3.medium, 2-5 nodes, no GPU
├── prod.tfvars         # Prod: t3.large, 3-15 nodes, GPU enabled
└── provider.tf         # Backend config (S3 bucket, DynamoDB)

2-eks-addons/
└── terraform.tfvars    # Addons configuration
```

**Contains**:
- AWS Region
- Cluster name
- Node types and sizes
- VPC CIDR
- S3 backend bucket
- DynamoDB table
- All infrastructure settings

### ✅ Jenkins Parameters (Build-time Selection)
When you build the pipeline, you select:
- **Environment**: dev / qa / prod
- **Action**: apply / destroy
- **Image Tag**: latest / v1.0.0 / commit-hash

Pipeline automatically uses the correct `.tfvars` file based on environment.

---

## 🚀 Pipeline 1: Infrastructure (Terraform)

### Purpose
Deploy EKS cluster and addons (folders 1-2)

### How to Use

1. **Create Jenkins Job**:
   ```
   New Item → Pipeline
   Name: Infrastructure-Pipeline
   Pipeline script from SCM
   Script Path: 6-jenkins-pipelines/1-infrastructure-pipeline.groovy
   ```

2. **Build with Parameters**:
   - **ENVIRONMENT**: Select dev / qa / prod
   - **ACTION**: Select apply / destroy

3. **What Happens**:

   **If ACTION = apply** (Create):
   ```
   Step 1: Init 01-infrastructure
   Step 2: Plan 01-infrastructure (uses dev.tfvars or prod.tfvars)
   Step 3: Apply 01-infrastructure
   Step 4: Init 02-eks-addons
   Step 5: Plan 02-eks-addons
   Step 6: Apply 02-eks-addons
   Step 7: Update kubeconfig
   ```

   **If ACTION = destroy** (Delete):
   ```
   Step 1: Confirm destroy (manual approval)
   Step 2: Init 02-eks-addons
   Step 3: Destroy 02-eks-addons (delete addons first)
   Step 4: Init 01-infrastructure
   Step 5: Destroy 01-infrastructure (delete cluster last)
   ```

### Automatic Features
- ✅ Selects correct `.tfvars` file based on environment
- ✅ Creates in correct order: 01 → 02
- ✅ Destroys in reverse order: 02 → 01
- ✅ Manual approval for production
- ✅ Updates kubeconfig after deployment

---

## 🚀 Pipeline 2: Application (Docker + K8s)

### Purpose
Build Docker images and deploy to Kubernetes (folders 3-4)

### How to Use

1. **Create Jenkins Job**:
   ```
   New Item → Pipeline
   Name: Application-Pipeline
   Pipeline script from SCM
   Script Path: 6-jenkins-pipelines/2-application-pipeline.groovy
   ```

2. **Build with Parameters**:
   - **ENVIRONMENT**: Select dev / qa / prod
   - **BUILD_IMAGES**: true / false
   - **DEPLOY_K8S**: true / false
   - **IMAGE_TAG**: latest (uses git commit) / v1.0.0 / custom

3. **What Happens**:

   **If BUILD_IMAGES = true**:
   ```
   Step 1: Get AWS account info
   Step 2: Login to ECR
   Step 3: Build 9 backend services
   Step 4: Build 1 frontend service
   Step 5: Push all images to ECR
   ```

   **If DEPLOY_K8S = true**:
   ```
   Step 1: Update K8s manifests with image tags
   Step 2: Deploy namespace
   Step 3: Deploy database
   Step 4: Deploy redis
   Step 5: Deploy backend services
   Step 6: Deploy frontend
   Step 7: Deploy ingresses (ALBs)
   Step 8: Deploy security and scaling
   Step 9: Verify deployment
   ```

### Automatic Features
- ✅ Gets AWS account ID and region automatically
- ✅ Uses git commit hash as image tag (if IMAGE_TAG = latest)
- ✅ Updates manifests with correct ECR registry
- ✅ Manual approval for production
- ✅ Verifies deployment after completion

---

## 🔄 Complete Workflow

### Initial Setup (One-time)

```
1. Install Jenkins plugins
2. Add AWS credentials to Jenkins
3. Create Infrastructure Pipeline job
4. Create Application Pipeline job
```

### Deploy to Dev

```
1. Run Infrastructure Pipeline
   - Environment: dev
   - Action: apply
   → Creates EKS cluster with dev.tfvars settings

2. Run Application Pipeline
   - Environment: dev
   - Build Images: true
   - Deploy K8s: true
   → Builds images and deploys application
```

### Deploy to Prod

```
1. Run Infrastructure Pipeline
   - Environment: prod
   - Action: apply
   → Creates EKS cluster with prod.tfvars settings
   → Requires manual approval

2. Run Application Pipeline
   - Environment: prod
   - Build Images: true
   - Deploy K8s: true
   - Image Tag: v1.0.0
   → Deploys to production
   → Requires manual approval
```

### Destroy Environment

```
Run Infrastructure Pipeline
- Environment: dev (or qa/prod)
- Action: destroy
→ Deletes in correct order: addons first, then cluster
→ Requires manual confirmation
```

---

## 📊 Pipeline Flow Diagram

```
┌─────────────────────────────────────────────────────────┐
│  Infrastructure Pipeline                                │
│                                                         │
│  Build Parameters:                                      │
│  ├─ ENVIRONMENT: dev/qa/prod                           │
│  └─ ACTION: apply/destroy                              │
│                                                         │
│  If ACTION = apply:                                     │
│  ├─ 01-infrastructure (uses {env}.tfvars)              │
│  └─ 02-eks-addons                                      │
│                                                         │
│  If ACTION = destroy:                                   │
│  ├─ 02-eks-addons (delete first)                       │
│  └─ 01-infrastructure (delete last)                    │
└─────────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────┐
│  Application Pipeline                                   │
│                                                         │
│  Build Parameters:                                      │
│  ├─ ENVIRONMENT: dev/qa/prod                           │
│  ├─ BUILD_IMAGES: true/false                           │
│  ├─ DEPLOY_K8S: true/false                             │
│  └─ IMAGE_TAG: latest/v1.0.0/custom                    │
│                                                         │
│  Steps:                                                 │
│  ├─ Build 10 Docker images                             │
│  ├─ Push to ECR                                        │
│  ├─ Update K8s manifests                               │
│  └─ Deploy to Kubernetes                               │
└─────────────────────────────────────────────────────────┘
```

---

## ✅ Key Features

### Simple Configuration
- ✅ No environment property files
- ✅ All config in Terraform files
- ✅ Only 2 types of Jenkins credentials
- ✅ Build-time parameter selection

### Correct Order
- ✅ **Create**: 01-infrastructure → 02-eks-addons
- ✅ **Destroy**: 02-eks-addons → 01-infrastructure (reverse)

### Safety
- ✅ Manual approval for production
- ✅ Confirmation required for destroy
- ✅ Automatic verification after deployment

### Flexibility
- ✅ Build images without deploying
- ✅ Deploy without building (use existing images)
- ✅ Custom image tags or git commit hash

---

## 🎯 Quick Start

### 1. Install Plugins
```bash
jenkins-cli install-plugin workflow-aggregator git docker-workflow \
  kubernetes-cli aws-credentials terraform credentials-binding
```

### 2. Add Credentials
```
- aws-credentials (AWS access key)
- kubeconfig-dev (dev cluster config)
- kubeconfig-qa (qa cluster config)
- kubeconfig-prod (prod cluster config)
```

### 3. Create Pipeline Jobs
```
Job 1: Infrastructure-Pipeline
- Script Path: 6-jenkins-pipelines/1-infrastructure-pipeline.groovy

Job 2: Application-Pipeline
- Script Path: 6-jenkins-pipelines/2-application-pipeline.groovy
```

### 4. Build!
```
Infrastructure Pipeline → Select env and action → Build
Application Pipeline → Select env and options → Build
```

---

**Simple, clean, and production-ready!** 🚀
