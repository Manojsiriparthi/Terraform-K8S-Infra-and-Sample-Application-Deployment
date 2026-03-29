# ShopEase - Production-Ready E-Commerce Platform on AWS EKS

A complete, production-ready e-commerce application deployed on AWS EKS with Terraform, featuring auto-scaling, monitoring, and security best practices.

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         AWS Cloud                                │
│                                                                   │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │                    VPC (10.2.0.0/16)                        │ │
│  │                                                              │ │
│  │  ┌──────────────┐         ┌──────────────────────────────┐ │ │
│  │  │ Public ALB   │         │   Internal ALB               │ │ │
│  │  │ (Frontend)   │         │   (Backend + Monitoring)     │ │ │
│  │  └──────┬───────┘         └──────┬───────────────────────┘ │ │
│  │         │                        │                          │ │
│  │  ┌──────▼───────┐         ┌─────▼──────┐  ┌─────────────┐ │ │
│  │  │  Frontend    │         │  Backend   │  │ Monitoring  │ │ │
│  │  │  (React)     │────────▶│  (Flask)   │  │ (Grafana)   │ │ │
│  │  │  Pods x2     │         │  Pods x2   │  │ Prometheus  │ │ │
│  │  └──────────────┘         └─────┬──────┘  │ Kibana      │ │ │
│  │                                 │         └─────────────┘ │ │
│  │                           ┌─────▼──────┐                  │ │
│  │                           │ PostgreSQL │                  │ │
│  │                           │ StatefulSet│                  │ │
│  │                           └────────────┘                  │ │
│  │                                                              │ │
│  │  ┌──────────────┐                                          │ │
│  │  │   Bastion    │  (SSH Tunnel for Monitoring Access)     │ │
│  │  └──────────────┘                                          │ │
│  └──────────────────────────────────────────────────────────┘ │
└───────────────────────────────────────────────────────────────┘
```

## 📁 Project Structure

```
.
├── 1-infrastructure/          # Terraform infrastructure code
│   ├── main.tf               # Main infrastructure
│   ├── modules/              # Reusable Terraform modules
│   │   ├── vpc/             # VPC, subnets, NAT, IGW
│   │   ├── eks/             # EKS cluster and node groups
│   │   ├── iam/             # IAM roles and policies
│   │   └── ec2-bastion/     # Bastion host
│   └── terraform.tfvars      # Configuration variables
│
├── 2-eks-addons/             # EKS add-ons and controllers
│   ├── aws-load-balancer-controller.tf
│   ├── cluster-autoscaler.tf
│   ├── ebs-csi-driver.tf
│   └── cloudwatch-observability.tf
│
├── 3-application/           # Application source code
│   ├── frontend/            # React frontend
│   │   ├── src/
│   │   │   ├── App.jsx      # Main app with routing
│   │   │   ├── App.css      # Styling
│   │   │   └── pages/       # Home, Cart, Payment, Profile
│   │   ├── Dockerfile
│   │   └── nginx.conf
│   ├── backend/             # Flask backend API
│   │   ├── app.py
│   │   ├── Dockerfile
│   │   └── requirements.txt
│   └── database/
│       └── init.sql         # Database schema with 24 products
│
├── 4-kubernetes-manifests/  # Kubernetes YAML files
│   ├── namespaces.yaml
│   ├── frontend.yaml        # Frontend deployment + public ALB
│   ├── backend.yaml         # Backend deployment + internal ALB
│   ├── database.yaml        # PostgreSQL StatefulSet
│   ├── monitoring-ingress.yaml  # Monitoring tools ingress
│   ├── storage.yaml
│   ├── rbac.yaml
│   ├── network-policies.yaml
│   └── hpa.yaml
│
├── 5-helm-charts/           # Helm charts
│   ├── shopease-app/        # Application Helm chart
│   └── monitoring/          # Monitoring stack Helm chart
│
├── 6-monitoring/            # Monitoring configuration
│   ├── prometheus-values.yaml
│   ├── elasticsearch-values.yaml
│   └── install-monitoring.sh
│
├── 7-jenkins/                # CI/CD pipelines
│   ├── Jenkinsfile-infrastructure
│   ├── Jenkinsfile-application-kubectl
│   └── Jenkinsfile-application-helm
│
├── 8-scripts/               # Deployment scripts
│   ├── run.sh               # Main deployment script
│   └── prerequisites.sh     # Install prerequisites
│
└── README.md                # This file
```

## ✨ Features

### Application Features
- 🛍️ **24 Products** - Men's and Women's clothing, shoes, and accessories
- 📄 **Pagination** - 8 products per page (3 pages total)
- 🛒 **Shopping Cart** - Add/remove items, quantity management
- 💳 **Checkout** - Card validation (12 digits + 3 digit CVV)
- 👤 **User Profile** - Create profile, view order history
- 📦 **Order Tracking** - Track order status (Processing → Shipped → Delivered)
- 📱 **Responsive Design** - Works on desktop and mobile

### Infrastructure Features
- ⚡ **Auto-Scaling** - HPA for frontend and backend
- 📊 **Monitoring** - Grafana, Prometheus, Elasticsearch, Kibana
- 🔒 **Security** - Network policies, RBAC, internal ALB for backend
- 🌐 **High Availability** - Multi-AZ deployment
- 💾 **Persistent Storage** - EBS volumes for database
- 🔄 **CI/CD Ready** - Jenkins pipelines included

## 🚀 Quick Start

### Prerequisites

```bash
# Install prerequisites
bash 8-scripts/prerequisites.sh
```

Required tools:
- AWS CLI (configured with credentials)
- Terraform >= 1.0
- kubectl >= 1.28
- Docker
- Helm >= 3.0

**Important:** Before deployment, review and update the configuration files:
- `1-infrastructure/terraform.tfvars` - Infrastructure settings (VPC, EKS, etc.)
- `2-eks-addons/terraform.tfvars` - Add-ons configuration

Key settings to review:
- `bastion_allowed_cidrs` - Restrict to your IP for security
- `vpc_cidr` - Ensure no conflicts with existing VPCs
- `cluster_version` - EKS version (currently 1.29)
- `node_instance_types` - Instance types for worker nodes

### Deployment

**Option 1: Deploy with kubectl (Recommended)**

```bash
cd 8-scripts
bash run.sh
# Choose option 1: Deploy with kubectl (1→2→3→4→6)
```

**Option 2: Deploy with Helm**

```bash
cd 8-scripts
bash run.sh
# Choose option 2: Deploy with Helm (1→2→3→5→6)
```

### Deployment Steps

The script will automatically:

1. **Layer 1: Infrastructure** (~15 minutes)
   - Create VPC with public/private subnets
   - Deploy EKS cluster
   - Create IAM roles
   - Launch bastion host

2. **Layer 2: EKS Add-ons** (~10 minutes)
   - Install AWS Load Balancer Controller
   - Configure Cluster Autoscaler
   - Setup EBS CSI Driver
   - Enable CloudWatch Observability

3. **Layer 3: Docker Images** (~5 minutes)
   - Build frontend and backend images
   - Push to ECR

4. **Layer 4: Application** (~5 minutes)
   - Deploy database (PostgreSQL)
   - Deploy backend (Flask API)
   - Deploy frontend (React)
   - Create ALB ingresses

5. **Layer 6: Monitoring** (~10 minutes)
   - Install Prometheus & Grafana
   - Install Elasticsearch & Kibana
   - Configure dashboards

**Total deployment time: ~45 minutes**

## 🌐 Accessing the Application

### Frontend (Public)

```bash
# Get frontend URL
kubectl get ingress frontend-ingress -n application -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

Open the URL in your browser. The application is publicly accessible.

**Features:**
- Browse 24 products with real images
- Add items to cart
- Complete checkout with card validation
- Create user profile
- Track orders

### Backend API (Internal)

The backend API is internal-only for security. Access via SSH tunnel:

```bash
# Get internal ALB URL
kubectl get ingress backend-ingress -n application -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

## 📊 Accessing Monitoring Tools

Monitoring tools (Grafana, Prometheus, Kibana) are on the internal ALB for security.

**📖 See detailed step-by-step guide:** [MONITORING-ACCESS-GUIDE.md](MONITORING-ACCESS-GUIDE.md)

### Quick Access Summary

1. Get bastion IP and internal ALB URL from your EC2
2. Create SSH tunnel from your laptop:
   ```bash
   ssh -i ~/Downloads/terraform.pem -L 8080:<INTERNAL_ALB>:80 ec2-user@<BASTION_IP>
   ```
3. Access in browser:
   - Grafana: http://localhost:8080/grafana (admin / changeme123)
   - Prometheus: http://localhost:8080/prometheus
   - Kibana: http://localhost:8080/kibana

## 🗑️ Cleanup

To destroy all resources:

```bash
cd 8-scripts
bash run.sh
# Choose option 3: Destroy kubectl deployment (6→4→3→2→1)
```

This will:
1. Delete monitoring stack
2. Delete application resources
3. Delete Docker images from ECR
4. Delete EKS add-ons
5. Destroy infrastructure (VPC, EKS, etc.)

**Note:** The destroy process includes aggressive VPC cleanup to handle AWS-managed resources.

## 📝 Configuration

### Update Product Catalog

Edit `3-application/database/init.sql` to modify products:

```sql
INSERT INTO products (name, category, price, image, stock, description) VALUES
('Product Name', 'Category', 99.99, 'https://image-url', 100, 'Description');
```

Then rebuild and redeploy:

```bash
cd 8-scripts
bash run.sh
# Choose option 7: Layer 3: Docker Images
# Choose option 8: Layer 4: Kubernetes Manifests
```

### Customize Infrastructure

Edit `1-infrastructure/terraform.tfvars`:

```hcl
aws_region          = "us-east-1"
cluster_name        = "shopease-eks"
cluster_version     = "1.29"
vpc_cidr            = "10.2.0.0/16"
node_instance_types = ["t3.medium"]
node_desired_size   = 2
node_min_size       = 2
node_max_size       = 4
```

## 🔐 Security Features

- ✅ **Network Segmentation** - Public/private subnets
- ✅ **Internal ALB** - Backend and monitoring not exposed to internet
- ✅ **Network Policies** - Pod-to-pod communication restrictions
- ✅ **RBAC** - Role-based access control
- ✅ **Secrets Management** - Kubernetes secrets for sensitive data
- ✅ **Security Groups** - Strict ingress/egress rules
- ✅ **Private EKS Nodes** - Worker nodes in private subnets

## 📈 Monitoring & Observability

### Grafana Dashboards

Pre-configured dashboards for:
- Kubernetes cluster metrics
- Node resource usage
- Pod performance
- Application metrics

### Prometheus Metrics

Collects metrics from:
- Kubernetes API server
- Node exporters
- Application pods
- EKS control plane

### Elasticsearch & Kibana

Centralized logging for:
- Application logs
- System logs
- Audit logs

## 🛠️ Troubleshooting

### Pods not starting

```bash
kubectl get pods -n application
kubectl describe pod <pod-name> -n application
kubectl logs <pod-name> -n application
```

### ALB not provisioning

```bash
kubectl get ingress -A
kubectl describe ingress <ingress-name> -n <namespace>

# Check ALB controller logs
kubectl logs -n kube-system deployment/aws-load-balancer-controller
```

### Database connection issues

```bash
# Check database pod
kubectl get pods -n application -l app=postgres

# Test connection
kubectl exec -it postgres-0 -n application -- psql -U shopease -d shopease -c "SELECT COUNT(*) FROM products;"
```

## 📚 Additional Resources

- [AWS EKS Documentation](https://docs.aws.amazon.com/eks/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [AWS Load Balancer Controller](https://kubernetes-sigs.github.io/aws-load-balancer-controller/)

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

---

**Built with ❤️ for production deployments on AWS EKS**
