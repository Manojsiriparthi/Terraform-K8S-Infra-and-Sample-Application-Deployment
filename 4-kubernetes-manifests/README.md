# Kubernetes Manifests - Production Deployment

## 📁 All Files (Flat Structure - No Subfolders)

```
4-kubernetes-manifests/
├── namespace.yaml                       # Application namespace
├── database.yaml                        # PostgreSQL (products, orders, customers)
├── redis.yaml                           # Redis cache (for cart)
├── backend-all.yaml                     # ⭐ All 9 backend services (single file)
├── frontend.yaml                        # Frontend service
├── frontend-ingress-external.yaml       # External ALB (internet-facing)
├── backend-ingress-internal.yaml        # Internal ALB (private)
├── monitoring-ingress-internal.yaml     # Monitoring (shares internal ALB)
├── network-policies.yaml                # Network security policies
├── hpa.yaml                             # Horizontal Pod Autoscalers
├── servicemonitor.yaml                  # Prometheus scrape config + alerts
├── monitoring-access-setup.yaml         # Multi-tenant Grafana setup (app1, app2)
├── monitoring-credentials.yaml          # Secrets for team access
├── gateway-classes.yaml                 # Gateway API (optional - future use)
├── gateway.yaml                         # Gateway resources (optional - future use)
└── README.md                            # This file
```

---

## 🚀 Jenkins Deployment Order

```bash
# Step 1: Namespace
kubectl apply -f namespace.yaml

# Step 2: Database (wait for ready)
kubectl apply -f database.yaml
kubectl wait --for=condition=ready pod -l app=postgres -n application --timeout=300s

# Step 3: Redis
kubectl apply -f redis.yaml
kubectl wait --for=condition=ready pod -l app=redis-cart -n application --timeout=120s

# Step 4: All Backend Services (single file)
kubectl apply -f backend-all.yaml
kubectl wait --for=condition=ready pod -l tier=backend -n application --timeout=300s

# Step 5: Frontend
kubectl apply -f frontend.yaml
kubectl wait --for=condition=ready pod -l app=frontend -n application --timeout=120s

# Step 6: Ingresses (ALBs)
kubectl apply -f frontend-ingress-external.yaml
kubectl apply -f backend-ingress-internal.yaml
kubectl apply -f monitoring-ingress-internal.yaml

# Step 7: Security
kubectl apply -f network-policies.yaml

# Step 8: Auto-scaling
kubectl apply -f hpa.yaml

# Step 9: Monitoring (Prometheus scraping)
kubectl apply -f servicemonitor.yaml

# Step 10: Multi-tenant Monitoring Setup (OPTIONAL - for team isolation)
# Only run these if you want separate Grafana orgs for different teams
# kubectl apply -f monitoring-credentials.yaml
# kubectl apply -f monitoring-access-setup.yaml
```

---

## 🔌 Database Connection

### PostgreSQL Service
- **Service Name**: `postgres-service`
- **Port**: `5432`
- **Database**: `shopease`
- **User**: `shopease`
- **Password**: `shopease123`

### Connection String
```
postgresql://shopease:shopease123@postgres-service:5432/shopease
```

### Services Using Database

1. **Product Catalog Service** (port 3550)
   - Reads products from `products` table
   - Environment variables in `backend-all.yaml`:
     ```yaml
     - name: DATABASE_URL
       value: "postgresql://shopease:shopease123@postgres-service:5432/shopease"
     - name: DB_HOST
       value: "postgres-service"
     - name: DB_PORT
       value: "5432"
     ```

2. **Checkout Service** (port 5050)
   - Stores orders in `orders` and `order_items` tables
   - Stores customers in `customers` table
   - Environment variable in `backend-all.yaml`:
     ```yaml
     - name: DATABASE_URL
       value: "postgresql://shopease:shopease123@postgres-service:5432/shopease"
     ```

### Database Tables
```sql
products          # Product catalog
customers         # Customer information  
orders            # Order records
order_items       # Order line items
```

---

## 📊 Backend Services (All in backend-all.yaml)

| Service | Language | Port | Database | Redis | Dependencies |
|---------|----------|------|----------|-------|--------------|
| adservice | Java | 9555 | ❌ | ❌ | None |
| cartservice | C# | 7070 | ❌ | ✅ | redis-cart:6379 |
| checkoutservice | Go | 5050 | ✅ | ❌ | cart, product, currency, email, payment, shipping |
| currencyservice | Node.js | 7000 | ❌ | ❌ | None |
| emailservice | Python | 8080 | ❌ | ❌ | None |
| paymentservice | Node.js | 50051 | ❌ | ❌ | None |
| productcatalogservice | Go | 3550 | ✅ | ❌ | postgres-service:5432 |
| recommendationservice | Python | 8080 | ❌ | ❌ | product |
| shippingservice | Go | 50051 | ❌ | ❌ | None |

---

## 🏗️ Architecture

```
Internet
   ↓
External ALB (frontend-ingress-external.yaml)
   ↓
Frontend (frontend.yaml)
   ↓
Internal ALB (backend-ingress-internal.yaml)
   ↓
Backend Services (backend-all.yaml)
   ├─ Product Catalog ──→ PostgreSQL (database.yaml)
   ├─ Checkout ──────────→ PostgreSQL (database.yaml)
   └─ Cart ──────────────→ Redis (redis.yaml)
```

---

## 🔍 Verification Commands

```bash
# Check all pods
kubectl get pods -n application

# Check services
kubectl get svc -n application

# Check ingresses
kubectl get ingress -n application

# Get frontend URL
kubectl get ingress frontend-ingress -n application \
  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'

# Get backend URL (internal)
kubectl get ingress backend-ingress -n application \
  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'

# Check HPA status
kubectl get hpa -n application

# Check database connection
kubectl exec -it -n application deployment/productcatalogservice -- nc -zv postgres-service 5432

# Check Redis connection
kubectl exec -it -n application deployment/cartservice -- nc -zv redis-cart 6379
```

---

## 📝 Before Deployment

### Update Image References
```bash
# Replace placeholders with your AWS account and region
find . -name "*.yaml" -type f -exec sed -i '' \
  's|<AWS_ACCOUNT_ID>|123456789012|g; s|<REGION>|us-east-1|g' {} +
```

### Change Database Password (Production)
Edit `database.yaml` and update:
```yaml
stringData:
  POSTGRES_PASSWORD: YOUR_SECURE_PASSWORD  # Change this!
```

---

## ✅ What's Included

- ✅ **Single backend file** (backend-all.yaml) - All 9 services in one file
- ✅ **No subfolders** - All files flat in 4-kubernetes-manifests/
- ✅ **Database connection** - PostgreSQL for products and orders
- ✅ **Redis cache** - For cart service
- ✅ **External ALB** - Internet-facing for frontend
- ✅ **Internal ALB** - Private for backend + monitoring
- ✅ **Network policies** - Pod security
- ✅ **Auto-scaling** - HPA for all services
- ✅ **Production ready** - Security contexts, resource limits, health checks

---

## 💰 Cost Estimate

| Resource | Monthly Cost |
|----------|--------------|
| External ALB | $16 |
| Internal ALB | $16 |
| EBS Volume (20GB) | $2 |
| **Total** | **~$34/month** |

*Excludes compute (EC2/Fargate) costs*

---

## 🎯 Jenkins Pipeline Example

```groovy
pipeline {
    agent any
    
    stages {
        stage('Deploy Namespace') {
            steps {
                sh 'kubectl apply -f namespace.yaml'
            }
        }
        
        stage('Deploy Database') {
            steps {
                sh 'kubectl apply -f database.yaml'
                sh 'kubectl wait --for=condition=ready pod -l app=postgres -n application --timeout=300s'
            }
        }
        
        stage('Deploy Redis') {
            steps {
                sh 'kubectl apply -f redis.yaml'
                sh 'kubectl wait --for=condition=ready pod -l app=redis-cart -n application --timeout=120s'
            }
        }
        
        stage('Deploy Backend') {
            steps {
                sh 'kubectl apply -f backend-all.yaml'
                sh 'kubectl wait --for=condition=ready pod -l tier=backend -n application --timeout=300s'
            }
        }
        
        stage('Deploy Frontend') {
            steps {
                sh 'kubectl apply -f frontend.yaml'
                sh 'kubectl wait --for=condition=ready pod -l app=frontend -n application --timeout=120s'
            }
        }
        
        stage('Deploy Ingresses') {
            steps {
                sh 'kubectl apply -f frontend-ingress-external.yaml'
                sh 'kubectl apply -f backend-ingress-internal.yaml'
                sh 'kubectl apply -f monitoring-ingress-internal.yaml'
            }
        }
        
        stage('Deploy Security & Scaling') {
            steps {
                sh 'kubectl apply -f network-policies.yaml'
                sh 'kubectl apply -f hpa.yaml'
            }
        }
        
        stage('Verify Deployment') {
            steps {
                sh 'kubectl get pods -n application'
                sh 'kubectl get svc -n application'
                sh 'kubectl get ingress -n application'
            }
        }
    }
}
```

---

**Ready for Jenkins deployment! All files are flat (no subfolders).** 🚀


---

## 🔐 Multi-Tenant Monitoring (Optional)

### Why Multi-Tenancy?

When you have **multiple applications** on the same cluster:
- **app1-team** should only see metrics/logs from `application` namespace
- **app2-team** should only see metrics/logs from `app2` namespace (future)
- **Platform team** has admin access to all monitoring

### Files for Multi-Tenancy:

1. **servicemonitor.yaml** - Tells Prometheus what to scrape
2. **monitoring-credentials.yaml** - Creates secrets for team access
3. **monitoring-access-setup.yaml** - Creates separate Grafana orgs for each team

### How It Works:

```
┌─────────────────────────────────────────────────────────┐
│  Prometheus (installed via Terraform 2-eks-addons)     │
│  ├─ Scrapes metrics from all namespaces                │
│  └─ Stores all metrics in one place                    │
└─────────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────┐
│  Grafana (installed via Terraform 2-eks-addons)         │
│  ├─ Org 1 (Main): Platform team - sees everything      │
│  ├─ Org 2 (app1): app1-team - sees only 'application'  │
│  └─ Org 3 (app2): app2-team - sees only 'app2'         │
└─────────────────────────────────────────────────────────┘
```

### Setup Steps:

```bash
# 1. Create secrets for team access
kubectl apply -f monitoring-credentials.yaml

# 2. Run setup jobs to create Grafana orgs
kubectl apply -f monitoring-access-setup.yaml

# 3. Wait for jobs to complete
kubectl get jobs -n monitoring

# 4. Access Grafana
# Platform team: http://internal-alb/grafana (admin/changeme-admin-password)
# App1 team: http://internal-alb/grafana (app1-admin/changeme-app1-password)
```

### Future: Adding App2

When you deploy a second application:

1. Deploy app2 to `app2` namespace
2. Update `monitoring-access-setup.yaml` (already has app2 config)
3. Run the setup job
4. App2 team gets their own Grafana org with access only to `app2` namespace

---

## 🌐 Gateway API (Optional - Future Use)

### Why Gateway API?

Gateway API is the **next-generation Ingress** - more flexible and powerful.

**Current Setup**: Uses Ingress resources
- ✅ `frontend-ingress-external.yaml` (External ALB)
- ✅ `backend-ingress-internal.yaml` (Internal ALB)

**Future Migration**: Can use Gateway API
- `gateway-classes.yaml` - Defines AWS ALB gateway class
- `gateway.yaml` - Gateway resources (replaces Ingress)

### When to Use Gateway API?

- ✅ Advanced routing (header-based, query-based)
- ✅ Traffic splitting (A/B testing, canary deployments)
- ✅ More flexible than Ingress
- ✅ Better multi-tenancy support

### Migration Path:

```bash
# 1. Enable Gateway API in Terraform
# Edit: 2-eks-addons/variables.tf
# Set: enable_gateway_api = true

# 2. Apply Terraform
terraform apply

# 3. Apply Gateway resources
kubectl apply -f gateway-classes.yaml
kubectl apply -f gateway.yaml

# 4. Migrate from Ingress to HTTPRoute (gradually)
```

**Note**: Current Ingress setup works perfectly fine. Only migrate if you need advanced features.

---

## 📊 File Purpose Summary

| File | Purpose | Required? | When to Use |
|------|---------|-----------|-------------|
| namespace.yaml | Application namespace | ✅ Required | Always |
| database.yaml | PostgreSQL database | ✅ Required | Always |
| redis.yaml | Redis cache | ✅ Required | Always |
| backend-all.yaml | All 9 backend services | ✅ Required | Always |
| frontend.yaml | Frontend service | ✅ Required | Always |
| frontend-ingress-external.yaml | External ALB | ✅ Required | Always |
| backend-ingress-internal.yaml | Internal ALB | ✅ Required | Always |
| monitoring-ingress-internal.yaml | Monitoring ALB | ✅ Required | Always |
| network-policies.yaml | Pod security | ✅ Required | Always |
| hpa.yaml | Auto-scaling | ✅ Required | Always |
| servicemonitor.yaml | Prometheus scraping | ✅ Required | Always |
| monitoring-credentials.yaml | Team access secrets | ⚠️ Optional | Multi-tenant setup |
| monitoring-access-setup.yaml | Grafana org setup | ⚠️ Optional | Multi-tenant setup |
| gateway-classes.yaml | Gateway API class | ⚠️ Optional | Future migration |
| gateway.yaml | Gateway resources | ⚠️ Optional | Future migration |

---

**Summary**: 
- **11 required files** for basic deployment
- **4 optional files** for multi-tenancy and future Gateway API migration
- All files are flat (no subfolders) for easy Jenkins deployment

