# ShopEase - Production-Grade E-Commerce Platform on AWS EKS

A complete, production-ready e-commerce platform deployed on Amazon EKS with comprehensive monitoring, security, and automation. This project demonstrates enterprise-grade infrastructure as code, containerized microservices, and CI/CD pipelines.

## � Project Structure

```
shopease-eks-platform/
├── 1-infrastructure/             # Layer 1: Core Infrastructure (Terraform)
│   ├── main.tf                   # Module orchestration
│   ├── variables.tf              # Input variables
│   ├── outputs.tf                # Infrastructure outputs
│   ├── provider.tf               # AWS provider configuration
│   ├── locals.tf                 # Local values and tags
│   ├── terraform.tfvars          # Variable values
│   └── modules/
│       ├── vpc/                  # VPC, Subnets, NAT, IGW, Route Tables
│       ├── iam/                  # IAM Roles and Policies
│       ├── ec2-bastion/          # Bastion Host (uses existing AWS key pair)
│       └── eks/                  # EKS Cluster, Node Groups, Security Groups
│
├── 2-eks-addons/                 # Layer 2: Kubernetes Addons (Terraform)
│   ├── provider.tf               # Kubernetes/Helm providers
│   ├── variables.tf              # Input variables
│   ├── outputs.tf                # Addon outputs
│   ├── locals.tf                 # Common values
│   ├── oidc.tf                   # OIDC Provider for IRSA
│   ├── ebs-csi-driver.tf         # Persistent volume support
│   ├── aws-load-balancer-controller.tf  # ALB/NLB integration
│   ├── cluster-autoscaler.tf     # Node autoscaling
│   ├── metrics-server.tf         # Resource metrics for HPA
│   ├── cloudwatch-observability.tf  # Container Insights
│   ├── fluent-bit.tf             # Log forwarding
│   └── policies/
│       └── aws-lb-controller-policy.json
│
├── 3-application/                # Layer 3: Application Code
│   ├── frontend/                 # React + Vite + Nginx
│   │   ├── src/
│   │   │   ├── App.jsx
│   │   │   ├── App.css
│   │   │   └── main.jsx
│   │   ├── index.html
│   │   ├── package.json
│   │   ├── vite.config.js
│   │   ├── nginx.conf
│   │   └── Dockerfile
│   ├── backend/                  # Flask + Gunicorn
│   │   ├── app.py
│   │   ├── requirements.txt
│   │   └── Dockerfile
│   └── database/
│       └── init.sql              # PostgreSQL schema and seed data
│
├── 4-kubernetes-manifests/       # Layer 4: Kubernetes Manifests (kubectl)
│   ├── namespaces.yaml           # application, monitoring, production
│   ├── rbac.yaml                 # All RBAC roles and bindings
│   ├── storage.yaml              # PersistentVolumeClaims
│   ├── database.yaml             # PostgreSQL StatefulSet + Service
│   ├── backend.yaml              # Backend Deployment + Service + Ingress (internal)
│   ├── frontend.yaml             # Frontend Deployment + Service + Ingress (public)
│   ├── hpa.yaml                  # Horizontal Pod Autoscalers
│   └── network-policies.yaml     # Pod-to-pod security policies
│
├── 5-helm-charts/                # Layer 5: Helm Charts
│   ├── shopease-app/             # Application Helm Chart
│   │   ├── Chart.yaml
│   │   ├── values.yaml
│   │   └── templates/
│   │       ├── namespace.yaml
│   │       ├── rbac.yaml
│   │       ├── database.yaml
│   │       ├── backend.yaml
│   │       ├── frontend.yaml
│   │       └── network-policies.yaml
│   └── monitoring/               # Monitoring Helm Chart
│       ├── Chart.yaml            # With dependencies
│       └── values.yaml           # Prometheus, Grafana, ELK
│
├── 6-monitoring/                 # Layer 6: Monitoring Stack
│   ├── prometheus-values.yaml    # Prometheus configuration
│   ├── elasticsearch-values.yaml # Elasticsearch configuration
│   ├── kibana-values.yaml        # Kibana configuration
│   ├── alerting-rules.yaml       # Alert definitions
│   └── install-monitoring.sh     # Installation script
│
├── 7-jenkins/                    # CI/CD Pipelines
│   ├── Jenkinsfile-infrastructure        # Infra deployment (1→2)
│   ├── Jenkinsfile-application-kubectl   # App deployment with kubectl (3→4→6)
│   ├── Jenkinsfile-application-helm      # App deployment with Helm (3→5→6)
│   ├── Jenkinsfile-monitoring            # Monitoring deployment (6)
│   └── README.md                          # Pipeline documentation
│
├── 8-scripts/                    # Automation Scripts
│   ├── run.sh                    # Main interactive deployment script
│   └── prerequisites.sh          # Validate required tools
│
├── keys/                         # SSH Keys (gitignored)
│   ├── .gitkeep                  # Keeps directory in git (actual .pem files ignored)
│   ├── README.md                 # Instructions for key setup
│   └── shopease-bastion-key.pem.example  # Example PEM file template
│
├── .gitignore                    # Git ignore rules
├── LICENSE                       # Project license
└── README.md                     # This file
```

## 📖 Project Description

ShopEase is a scalable e-commerce application built with modern cloud-native technologies. The platform consists of a React frontend, Flask backend API, and PostgreSQL database, all running on Amazon EKS with full observability and security controls.

The infrastructure is designed with modularity, security, and cost optimization in mind, following AWS best practices and production-grade patterns. It supports multiple deployment methods (kubectl or Helm) and includes complete CI/CD pipelines for automated deployments across dev, qa, and production environments.

---

## 🏗️ Layer-by-Layer Breakdown

### Layer 1: Core Infrastructure (1-infrastructure/)

**Purpose**: Establishes the foundational AWS infrastructure using modular Terraform.

**What it creates**:
- **VPC Module**: Creates a multi-AZ Virtual Private Cloud with public and private subnets across two availability zones. Includes Internet Gateway for public access and NAT Gateways in each AZ for private subnet internet access. Subnets are tagged for EKS integration.

- **IAM Module**: Defines all IAM roles and policies needed for the platform. Creates roles for the bastion host (with SSM access), EKS cluster control plane, and EKS worker nodes (with ECR, CNI, and SSM permissions).

- **EC2 Bastion Module**: Deploys a hardened bastion host in a public subnet for secure cluster access. Uses an existing AWS key pair that you create manually in the AWS Console. The bastion is configured with IMDSv2 and encrypted storage.

  **How PEM keys work**:
  1. Before deployment, create a key pair in AWS Console (EC2 → Key Pairs → Create)
  2. Download the .pem file and save it to `keys/shopease-bastion-key.pem` in your local repo
  3. The `keys/` directory is gitignored to prevent committing sensitive keys to version control
  4. `.gitkeep` file ensures the empty directory structure is tracked in git
  5. Terraform uses `data.aws_key_pair` to reference your existing key pair (no generation)
  6. To access bastion: `ssh -i keys/shopease-bastion-key.pem ec2-user@<bastion-ip>`
  7. Alternative: Use AWS SSM Session Manager (no key needed): `aws ssm start-session --target <instance-id>`

- **EKS Module**: Creates the Kubernetes cluster with separate node groups for public and private workloads. Configures security groups, enables control plane logging, and sets up the cluster with proper networking and access controls.

**How it works**: Each module is self-contained with its own variables, resources, and outputs. The main orchestration file calls these modules in the correct order, passing outputs between them. All resources are tagged consistently for cost tracking and management.

---

### Layer 2: EKS Addons (2-eks-addons/)

**Purpose**: Installs essential Kubernetes addons and AWS integrations that enable the cluster to function properly.

**What it creates**:
- **OIDC Provider**: Creates an OpenID Connect provider that enables IAM Roles for Service Accounts (IRSA). This allows Kubernetes pods to assume AWS IAM roles securely without storing credentials.

- **EBS CSI Driver**: Enables persistent storage for stateful workloads. Creates a default GP3 storage class with encryption enabled, allowing pods to request persistent volumes dynamically.

- **AWS Load Balancer Controller**: Automatically provisions Application Load Balancers when Ingress resources are created. Manages ALB lifecycle, target groups, and health checks based on Kubernetes annotations.

- **Cluster Autoscaler**: Monitors pod resource requests and automatically scales node groups up or down based on demand. Prevents resource waste while ensuring pods can always be scheduled.

- **Metrics Server**: Collects resource metrics from nodes and pods, enabling Horizontal Pod Autoscaler (HPA) and kubectl top commands.

- **CloudWatch Observability**: Deploys Container Insights for cluster-level monitoring. Provides automatic dashboards for cluster performance, node health, and pod metrics in CloudWatch.

- **Fluent Bit**: Runs as a DaemonSet on every node, collecting container logs and system logs. Forwards logs to both CloudWatch Logs (for AWS-native monitoring) and Elasticsearch (for advanced log analysis).

**How it works**: This layer depends on Layer 1 outputs (cluster name, OIDC issuer URL). Each addon uses IRSA to securely access AWS services. The OIDC provider must be created here because it needs the EKS cluster to exist first.

---

### Layer 3: Application Code (3-application/)

**Purpose**: Contains the containerized application components ready for deployment.

**What it includes**:
- **Frontend**: React-based single-page application built with Vite. Uses Nginx as a reverse proxy to serve static files and proxy API requests to the backend. Includes health checks and optimized Docker multi-stage build.

- **Backend**: Flask REST API that handles product listings, order management, and database operations. Uses Gunicorn as the production WSGI server with multiple workers for concurrent request handling.

- **Database**: PostgreSQL initialization scripts that create the database schema (products, orders, order_items) and populate sample data for testing.

**How it works**: Each component is containerized with optimized Dockerfiles. Images are built and pushed to Amazon ECR, then referenced by Kubernetes manifests or Helm charts. The frontend communicates with the backend via internal service discovery, and the backend connects to the database using Kubernetes secrets.

---

### Layer 4: Kubernetes Manifests (4-kubernetes-manifests/)

**Purpose**: Provides raw Kubernetes YAML manifests for kubectl-based deployment.

**What it creates**:
- **Namespaces**: Separates workloads into logical boundaries (application, monitoring, production) for isolation and access control.

- **RBAC**: Defines role-based access control with four roles: developers (read-only pod access), devops (full cluster access), database-admins (database pod access only), and monitoring-viewers (monitoring namespace read access).

- **Storage**: Creates PersistentVolumeClaims using the EBS CSI driver for database storage.

- **Database**: Deploys PostgreSQL as a StatefulSet with persistent storage. StatefulSets ensure stable network identities and persistent data even if pods are rescheduled. Includes health checks and resource limits.

- **Backend**: Deploys the API as a stateless Deployment with multiple replicas. Creates an internal Application Load Balancer (private, VPC-only access) for secure backend communication.

- **Frontend**: Deploys the web interface as a stateless Deployment. Creates a public-facing Application Load Balancer for internet access.

- **HPA**: Configures Horizontal Pod Autoscalers that automatically scale frontend and backend based on CPU and memory usage.

- **Network Policies**: Implements pod-to-pod security rules. Frontend can only talk to backend, backend can only talk to database, and database accepts connections only from backend.

**How it works**: Manifests are applied in a specific order to handle dependencies. Namespaces first, then RBAC, storage, database (wait for ready), then stateless apps, then autoscaling and network policies. The AWS Load Balancer Controller automatically provisions ALBs based on Ingress annotations.

---

### Layer 5: Helm Charts (5-helm-charts/)

**Purpose**: Provides an alternative deployment method using Helm for easier management and upgrades.

**What it includes**:
- **ShopEase App Chart**: Packages all application components (frontend, backend, database, RBAC, network policies) into a single Helm release. Uses templating for environment-specific configurations.

- **Monitoring Chart**: Defines dependencies on community Helm charts (Prometheus, Grafana, Elasticsearch, Kibana) with custom values for the ShopEase platform.

**How it works**: Helm charts use Go templating to generate Kubernetes manifests dynamically based on values.yaml. This allows the same chart to be deployed across multiple environments with different configurations. Helm tracks releases and enables easy rollbacks, upgrades, and uninstalls.

**Advantages over kubectl**: Version control for deployments, easy rollbacks, templating for multi-environment support, dependency management, and simplified upgrades.

---

### Layer 6: Monitoring Stack (6-monitoring/)

**Purpose**: Provides comprehensive observability for the entire platform.

**What it deploys**:
- **Prometheus**: Collects metrics from Kubernetes components, nodes, and application pods. Stores time-series data for performance analysis and alerting.

- **Grafana**: Visualization platform with pre-built dashboards for cluster health, resource usage, and application performance. Accessible via LoadBalancer or port-forward.

- **Elasticsearch**: Stores logs forwarded by Fluent Bit from all containers and system components. Provides powerful search and aggregation capabilities.

- **Kibana**: Web interface for Elasticsearch. Allows log searching, filtering, visualization, and dashboard creation. Essential for troubleshooting and log analysis.

- **Alerting Rules**: Pre-configured alerts for high CPU/memory, pod crashes, application errors, and storage issues.

**How it works**: Fluent Bit (deployed in Layer 2) collects logs and sends them to both CloudWatch and Elasticsearch. Prometheus scrapes metrics from Kubernetes API and node exporters. Grafana connects to Prometheus for visualization. All monitoring components run in the dedicated monitoring namespace with persistent storage.

---

## 🛠️ Scripts and Automation

### 8-scripts/run.sh

**Purpose**: Single interactive script for all deployment and management operations.

**Features**:
- Interactive menu with numbered options
- Prerequisites validation (checks for Terraform, AWS CLI, kubectl, Helm, Docker)
- Auto-detects AWS account ID and configures ECR registry
- Handles complete deployment workflows
- Supports individual layer deployment
- Proper destroy order (reverse of creation)
- Color-coded output for clarity
- Shows deployment outputs and access URLs

**Options**:
1. Deploy with kubectl (1→2→3→4→6)
2. Deploy with Helm (1→2→3→5→6)
3. Destroy kubectl deployment (6→4→3→2→1)
4. Destroy Helm deployment (6→5→3→2→1)
5-10. Deploy individual layers
11. Show outputs
12. Check prerequisites

**Usage**: Simply run `./8-scripts/run.sh` and follow the interactive prompts.

---

### 8-scripts/prerequisites.sh

**Purpose**: Standalone script to validate all required tools are installed before deployment.

**Checks**:
- Terraform, AWS CLI, kubectl, Helm, Docker, jq
- AWS credentials configuration
- Displays versions of installed tools

**Usage**: Run before any deployment to ensure your environment is ready.

---

## 🔄 Jenkins CI/CD Pipelines

### 7-jenkins/Jenkinsfile-infrastructure

**Purpose**: Automates infrastructure deployment across multiple environments.

**Pipeline Flow**:
1. Checkout code from repository
2. Validate prerequisites (Terraform, AWS CLI)
3. Deploy Layer 1 (Infrastructure) with Terraform workspaces
4. Deploy Layer 2 (EKS Addons)
5. Configure kubectl for cluster access

**Parameters**:
- ENVIRONMENT: dev, qa, prod
- ACTION: plan, apply, destroy
- AWS_REGION: Target AWS region

**Use Case**: Infrastructure team deploys base infrastructure for each environment. Supports plan-before-apply workflow for safety.

---

### 7-jenkins/Jenkinsfile-application-kubectl

**Purpose**: Builds, tests, and deploys application using Kubernetes manifests.

**Pipeline Flow**:
1. Checkout code
2. Run backend tests (Python/pytest)
3. Run frontend tests (npm build)
4. Build Docker images for frontend and backend
5. Push images to Amazon ECR
6. Update Kubernetes manifests with image URLs
7. Configure kubectl
8. Deploy manifests to cluster (Layer 4)
9. Optionally deploy monitoring (Layer 6)
10. Verify deployment health

**Parameters**:
- ENVIRONMENT: dev, qa, prod
- IMAGE_TAG: Docker image version
- SKIP_TESTS: Skip testing phase
- DEPLOY_MONITORING: Include monitoring deployment

**Use Case**: Application team deploys code changes. Runs on every merge to main branch or manual trigger.

---

### 7-jenkins/Jenkinsfile-application-helm

**Purpose**: Builds, tests, and deploys application using Helm charts.

**Pipeline Flow**:
1. Checkout code
2. Run backend tests (Python/pytest)
3. Run frontend tests (npm build)
4. Build Docker images for frontend and backend
5. Push images to Amazon ECR
6. Update Helm values with image URLs
7. Configure kubectl
8. Deploy Helm chart (Layer 5)
9. Optionally deploy monitoring (Layer 6)
10. Verify deployment health

**Parameters**:
- ENVIRONMENT: dev, qa, prod
- IMAGE_TAG: Docker image version
- SKIP_TESTS: Skip testing phase
- DEPLOY_MONITORING: Include monitoring deployment

**Use Case**: Same as kubectl pipeline but uses Helm for easier version management and rollbacks. Preferred for production environments.

---

### 7-jenkins/Jenkinsfile-monitoring

**Purpose**: Independently manages the monitoring stack.

**Pipeline Flow**:
1. Checkout code
2. Configure kubectl
3. Install/upgrade or uninstall monitoring components
4. Verify monitoring services

**Parameters**:
- ENVIRONMENT: dev, qa, prod
- ACTION: install, upgrade, uninstall
- AWS_REGION: Target AWS region

**Use Case**: Platform team manages monitoring infrastructure separately from applications. Allows monitoring updates without touching application deployments.

---

## � Deployment Steps

### Prerequisites
1. Install required tools: Terraform, AWS CLI, kubectl, Helm, Docker
2. Configure AWS credentials: `aws configure`
3. Verify setup: `./8-scripts/prerequisites.sh`

### Method 1: Interactive Deployment (Recommended for Manual)

```bash
chmod +x 8-scripts/run.sh
./8-scripts/run.sh
```

Select option 1 (kubectl) or 2 (Helm) from the menu. The script will:
- Validate prerequisites
- Deploy infrastructure (VPC, EKS, Bastion)
- Install EKS addons (OIDC, ALB Controller, Autoscaler, etc.)
- Build and push Docker images to ECR
- Deploy application to Kubernetes
- Install monitoring stack
- Display access URLs and outputs

### Method 2: CI/CD Deployment (Recommended for Production)

**Step 1: Setup Jenkins**
- Install Jenkins with required plugins (Pipeline, AWS Steps, Kubernetes CLI, Docker)
- Configure AWS credentials in Jenkins
- Create four pipeline jobs pointing to respective Jenkinsfiles

**Step 2: Deploy Infrastructure**
- Run `shopease-infrastructure` pipeline
- Select ENVIRONMENT (dev/qa/prod) and ACTION (apply)
- Pipeline deploys Layers 1 and 2
- Outputs cluster name and endpoints

**Step 3: Deploy Application**
- Run `shopease-app-kubectl` or `shopease-app-helm` pipeline
- Select ENVIRONMENT and IMAGE_TAG
- Pipeline builds images, pushes to ECR, and deploys to cluster
- Optionally deploys monitoring stack

**Step 4: Access Application**
- Frontend URL: Check Ingress output (public ALB)
- Backend URL: Internal ALB (accessible only from VPC)
- Grafana: Port-forward to localhost:3000
- Kibana: LoadBalancer URL or port-forward to localhost:5601

### Deployment Success Indicators

✅ All Terraform applies complete without errors
✅ EKS cluster status shows ACTIVE
✅ All pods reach Running state
✅ Ingress resources show ALB hostnames
✅ Health checks pass for all services
✅ Monitoring dashboards display metrics
✅ Logs appear in CloudWatch and Kibana

---

## 🔒 Security Features

### Network Security
- **Multi-layer isolation**: Public and private subnets with separate node groups
- **Network policies**: Strict pod-to-pod communication rules (frontend→backend→database only)
- **Security groups**: Minimal port exposure with specific ingress/egress rules
- **Private backend**: Backend API accessible only within VPC via internal ALB
- **Public frontend**: Only the web interface exposed to internet via public ALB

### Access Control
- **RBAC**: Four distinct roles with least-privilege access (developers, devops, database-admins, monitoring-viewers)
- **IRSA**: IAM Roles for Service Accounts eliminates need for static credentials
- **SSM access**: Bastion and nodes accessible via AWS Systems Manager (no SSH keys needed)
- **IMDSv2**: Enforced on all EC2 instances to prevent SSRF attacks

### Data Security
- **Encrypted storage**: All EBS volumes encrypted at rest
- **Secrets management**: Database credentials stored in Kubernetes Secrets
- **TLS certificates**: ALB supports HTTPS termination (configure ACM certificates)
- **Private key protection**: SSH keys stored in gitignored directory with 0400 permissions

### Compliance
- **Audit logging**: EKS control plane logs sent to CloudWatch
- **Container scanning**: ECR image scanning enabled on push
- **Resource tagging**: All resources tagged for compliance tracking
- **Immutable infrastructure**: Infrastructure as code ensures reproducibility

---

## 💰 Cost Optimization

### Infrastructure Costs
- **EKS Control Plane**: $73/month (fixed)
- **EC2 Nodes**: ~$95/month (3 nodes: 2x t3.medium + 1x t3.small)
- **NAT Gateways**: ~$65/month (2 AZs for high availability)
- **EBS Volumes**: ~$30/month (node storage + database PV)
- **Load Balancers**: ~$40/month (2 ALBs: public + internal)
- **Data Transfer**: Variable based on traffic
- **CloudWatch**: ~$10/month (logs and metrics)

**Estimated Total**: $300-350/month for production environment

### Cost Optimization Strategies

**Implemented**:
- **Cluster Autoscaler**: Automatically removes unused nodes during low traffic
- **HPA**: Scales pods based on actual demand (min 2, max 10 for backend)
- **GP3 volumes**: More cost-effective than GP2 with better performance
- **Spot instances**: Can be configured for non-critical workloads (update node group capacity_type)
- **Resource limits**: Prevents resource waste with defined CPU/memory limits
- **Single NAT per AZ**: Balances cost and high availability

**Additional Optimizations**:
- Use Fargate for burst workloads (pay per pod)
- Enable S3 backend for Terraform state (included but commented)
- Use Reserved Instances for predictable workloads (40-60% savings)
- Implement pod disruption budgets for safe node termination
- Schedule non-production environments to shut down after hours
- Use AWS Savings Plans for long-term commitments

**Cost Monitoring**:
- All resources tagged with CostCenter and Environment
- Use AWS Cost Explorer to track spending by tag
- Set up billing alerts in CloudWatch
- Review CloudWatch Logs retention policies (default 30 days)

---

## 📊 Monitoring and Observability

### Infrastructure Monitoring
- **CloudWatch Container Insights**: Cluster-level metrics, node performance, pod resource usage
- **CloudWatch Logs**: Centralized logs from all containers and system components
- **Fluent Bit**: Collects and forwards logs with minimal resource overhead

### Application Monitoring
- **Prometheus**: Scrapes metrics from Kubernetes API, nodes, and application endpoints
- **Grafana**: Pre-built dashboards for cluster health, resource usage, and application performance
- **Elasticsearch**: Stores logs for long-term retention and advanced analysis
- **Kibana**: Search, filter, and visualize logs with custom dashboards

### Alerting
- Pre-configured alerts for high CPU/memory, pod crashes, application errors, and storage issues
- Alerts can be routed to Slack, PagerDuty, or email via Alertmanager

---

## 🎯 Deployment Flexibility

### Two Deployment Methods

**kubectl (Layer 4)**:
- Direct Kubernetes manifest application
- Simple and transparent
- Good for learning and debugging
- Manual updates required for configuration changes

**Helm (Layer 5)**:
- Package manager for Kubernetes
- Version-controlled releases
- Easy rollbacks and upgrades
- Templating for multi-environment support
- Preferred for production

Both methods deploy identical infrastructure with the same features (StatefulSets, Deployments, ALBs, HPA, RBAC, network policies).

---

## 🔮 Future Enhancements

### Security
- Implement AWS WAF on ALBs for DDoS protection
- Add Falco for runtime security monitoring
- Enable Pod Security Standards (restricted mode)
- Integrate AWS Secrets Manager for credential rotation
- Implement mutual TLS between services
- Add OPA/Gatekeeper for policy enforcement

### Scalability
- Multi-region deployment with Route53 failover
- Implement Redis for session management and caching
- Add CDN (CloudFront) for static asset delivery
- Database read replicas for improved performance
- Implement API rate limiting and throttling

### Observability
- Distributed tracing with AWS X-Ray or Jaeger
- Custom application metrics with Prometheus client libraries
- Service mesh (Istio/Linkerd) for advanced traffic management
- Synthetic monitoring for uptime checks

### CI/CD
- GitOps with ArgoCD or Flux
- Automated security scanning in pipeline (Trivy, Snyk)
- Blue-green or canary deployments
- Automated rollback on failed health checks
- Integration tests in staging environment

### Cost Optimization
- Implement Karpenter for more efficient autoscaling
- Use Spot instances for non-critical workloads
- Implement pod priority and preemption
- Add Kubecost for granular cost tracking
- Schedule dev/qa environment shutdowns

### Application Features
- Implement shopping cart persistence
- Add payment gateway integration
- User authentication and authorization
- Product search with Elasticsearch
- Email notifications for orders
- Admin dashboard for inventory management

---

**Built with**: Terraform, Kubernetes, Docker, AWS EKS, Helm, Jenkins
**Deployment Time**: 60-90 minutes for full stack
**Status**: Production-Ready ✅
