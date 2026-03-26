#!/bin/bash

# ============================================================================
# SHOPEASE DEPLOYMENT SCRIPT
# Single script to handle all deployment and destroy operations
# ============================================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

AWS_REGION=${AWS_REGION:-us-east-1}
AWS_ACCOUNT_ID=""
ECR_REGISTRY=""
CLUSTER_NAME=""

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

print_header() {
    echo ""
    echo -e "${BLUE}=========================================="
    echo -e "$1"
    echo -e "==========================================${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${CYAN}ℹ $1${NC}"
}

# Check prerequisites
check_prerequisites() {
    print_header "Checking Prerequisites"
    
    local missing=0
    
    for tool in terraform aws kubectl helm docker jq; do
        if command -v $tool &> /dev/null; then
            print_success "$tool is installed"
        else
            print_error "$tool is NOT installed"
            missing=1
        fi
    done
    
    if [ $missing -eq 1 ]; then
        print_error "Missing required tools. Please install them first."
        exit 1
    fi
    
    # Check AWS credentials
    if aws sts get-caller-identity &> /dev/null; then
        AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
        ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
        print_success "AWS credentials configured (Account: ${AWS_ACCOUNT_ID})"
    else
        print_error "AWS credentials not configured"
        exit 1
    fi
    
    print_success "All prerequisites met"
}

# ============================================================================
# DEPLOYMENT FUNCTIONS
# ============================================================================

deploy_layer1() {
    print_header "LAYER 1: Deploying Infrastructure"
    cd 1-infrastructure
    terraform init -upgrade
    terraform plan -out=tfplan
    terraform apply tfplan
    rm -f tfplan
    cd ..
    print_success "Infrastructure deployed"
}

deploy_layer2() {
    print_header "LAYER 2: Deploying EKS Addons"
    cd 2-eks-addons
    terraform init -upgrade
    terraform plan -out=tfplan
    terraform apply tfplan
    rm -f tfplan
    cd ..
    print_success "EKS Addons deployed"
    
    # Configure kubectl
    print_info "Configuring kubectl..."
    CLUSTER_NAME=$(cd 1-infrastructure && terraform output -raw cluster_name)
    aws eks update-kubeconfig --region ${AWS_REGION} --name ${CLUSTER_NAME}
    print_success "kubectl configured for ${CLUSTER_NAME}"
}

deploy_layer3() {
    print_header "LAYER 3: Building and Pushing Docker Images"
    
    # Create ECR repositories
    print_info "Creating ECR repositories..."
    aws ecr describe-repositories --repository-names shopease-frontend --region ${AWS_REGION} 2>/dev/null || \
        aws ecr create-repository --repository-name shopease-frontend --region ${AWS_REGION} --image-scanning-configuration scanOnPush=true
    
    aws ecr describe-repositories --repository-names shopease-backend --region ${AWS_REGION} 2>/dev/null || \
        aws ecr create-repository --repository-name shopease-backend --region ${AWS_REGION} --image-scanning-configuration scanOnPush=true
    
    print_success "ECR repositories ready"
    
    # Login to ECR
    print_info "Logging into ECR..."
    aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY}
    print_success "Logged into ECR"
    
    # Build and push frontend
    print_info "Building frontend image..."
    cd 3-application/frontend
    docker build -t shopease-frontend:latest .
    docker tag shopease-frontend:latest ${ECR_REGISTRY}/shopease-frontend:latest
    docker push ${ECR_REGISTRY}/shopease-frontend:latest
    cd ../..
    print_success "Frontend image pushed"
    
    # Build and push backend
    print_info "Building backend image..."
    cd 3-application/backend
    docker build -t shopease-backend:latest .
    docker tag shopease-backend:latest ${ECR_REGISTRY}/shopease-backend:latest
    docker push ${ECR_REGISTRY}/shopease-backend:latest
    cd ../..
    print_success "Backend image pushed"
    
    print_success "Docker images deployed to ECR"
}

deploy_layer4() {
    print_header "LAYER 4: Deploying Kubernetes Manifests"
    
    # Update image URLs
    print_info "Updating image URLs in manifests..."
    sed -i.bak "s|<AWS_ACCOUNT_ID>|${AWS_ACCOUNT_ID}|g" 4-k8s-manifests/backend.yaml
    sed -i.bak "s|<REGION>|${AWS_REGION}|g" 4-k8s-manifests/backend.yaml
    sed -i.bak "s|<AWS_ACCOUNT_ID>|${AWS_ACCOUNT_ID}|g" 4-k8s-manifests/frontend.yaml
    sed -i.bak "s|<REGION>|${AWS_REGION}|g" 4-k8s-manifests/frontend.yaml
    rm -f 4-k8s-manifests/*.bak
    
    # Deploy in order
    print_info "Creating namespaces..."
    kubectl apply -f 4-k8s-manifests/namespaces.yaml
    
    print_info "Configuring RBAC..."
    kubectl apply -f 4-k8s-manifests/rbac.yaml
    
    print_info "Creating storage..."
    kubectl apply -f 4-k8s-manifests/storage.yaml
    
    print_info "Deploying database..."
    kubectl apply -f 4-k8s-manifests/database.yaml
    
    print_info "Waiting for database to be ready..."
    kubectl wait --for=condition=ready pod -l app=postgres -n application --timeout=300s || true
    
    print_info "Deploying backend..."
    kubectl apply -f 4-k8s-manifests/backend.yaml
    
    print_info "Deploying frontend..."
    kubectl apply -f 4-k8s-manifests/frontend.yaml
    
    print_info "Configuring HPA..."
    kubectl apply -f 4-k8s-manifests/hpa.yaml
    
    print_info "Applying network policies..."
    kubectl apply -f 4-k8s-manifests/network-policies.yaml
    
    print_success "Kubernetes manifests deployed"
}

deploy_layer5() {
    print_header "LAYER 5: Deploying Helm Chart"
    
    # Update image URLs
    print_info "Updating Helm values..."
    sed -i.bak "s|<AWS_ACCOUNT_ID>|${AWS_ACCOUNT_ID}|g" 5-helm-charts/shopease-app/values.yaml
    sed -i.bak "s|<REGION>|${AWS_REGION}|g" 5-helm-charts/shopease-app/values.yaml
    rm -f 5-helm-charts/shopease-app/values.yaml.bak
    
    # Deploy Helm chart
    print_info "Installing Helm chart..."
    helm upgrade --install shopease ./5-helm-charts/shopease-app \
        --namespace application \
        --create-namespace \
        --wait \
        --timeout 10m
    
    print_success "Helm chart deployed"
}

deploy_layer6() {
    print_header "LAYER 6: Deploying Monitoring Stack"
    cd 6-monitoring
    chmod +x install-monitoring.sh
    ./install-monitoring.sh
    cd ..
    print_success "Monitoring stack deployed"
}

# ============================================================================
# DESTROY FUNCTIONS
# ============================================================================

destroy_layer6() {
    print_header "DESTROYING LAYER 6: Monitoring"
    helm uninstall prometheus -n monitoring 2>/dev/null || true
    helm uninstall elasticsearch -n monitoring 2>/dev/null || true
    helm uninstall kibana -n monitoring 2>/dev/null || true
    kubectl delete namespace monitoring --ignore-not-found=true
    print_success "Layer 6 destroyed"
}

destroy_layer5() {
    print_header "DESTROYING LAYER 5: Helm Application"
    helm uninstall shopease -n application 2>/dev/null || true
    kubectl delete namespace application --ignore-not-found=true
    kubectl delete namespace production --ignore-not-found=true
    print_success "Layer 5 destroyed"
}

destroy_layer4() {
    print_header "DESTROYING LAYER 4: Kubernetes Manifests"
    kubectl delete -f 4-k8s-manifests/network-policies.yaml --ignore-not-found=true
    kubectl delete -f 4-k8s-manifests/hpa.yaml --ignore-not-found=true
    kubectl delete -f 4-k8s-manifests/frontend.yaml --ignore-not-found=true
    kubectl delete -f 4-k8s-manifests/backend.yaml --ignore-not-found=true
    kubectl delete -f 4-k8s-manifests/database.yaml --ignore-not-found=true
    kubectl delete -f 4-k8s-manifests/storage.yaml --ignore-not-found=true
    kubectl delete -f 4-k8s-manifests/rbac.yaml --ignore-not-found=true
    kubectl delete -f 4-k8s-manifests/namespaces.yaml --ignore-not-found=true
    print_success "Layer 4 destroyed"
}

destroy_layer3() {
    print_header "DESTROYING LAYER 3: Docker Images"
    aws ecr delete-repository --repository-name shopease-frontend --region ${AWS_REGION} --force 2>/dev/null || true
    aws ecr delete-repository --repository-name shopease-backend --region ${AWS_REGION} --force 2>/dev/null || true
    print_success "Layer 3 destroyed"
}

destroy_layer2() {
    print_header "DESTROYING LAYER 2: EKS Addons"
    cd 2-eks-addons
    terraform destroy -auto-approve
    cd ..
    print_success "Layer 2 destroyed"
}

destroy_layer1() {
    print_header "DESTROYING LAYER 1: Infrastructure"
    cd 1-infrastructure
    terraform destroy -auto-approve
    cd ..
    print_success "Layer 1 destroyed"
}

# ============================================================================
# DEPLOYMENT WORKFLOWS
# ============================================================================

deploy_option1() {
    print_header "OPTION 1: Deploy with kubectl (1→2→3→4→6)"
    check_prerequisites
    deploy_layer1
    deploy_layer2
    deploy_layer3
    deploy_layer4
    deploy_layer6
    show_outputs
}

deploy_option2() {
    print_header "OPTION 2: Deploy with Helm (1→2→3→5→6)"
    check_prerequisites
    deploy_layer1
    deploy_layer2
    deploy_layer3
    deploy_layer5
    deploy_layer6
    show_outputs
}

destroy_option3() {
    print_header "OPTION 3: Destroy kubectl deployment (6→4→3→2→1)"
    print_warning "This will destroy ALL resources!"
    read -p "Type 'yes' to confirm: " confirm
    if [ "$confirm" != "yes" ]; then
        print_warning "Destroy cancelled"
        return
    fi
    destroy_layer6
    destroy_layer4
    destroy_layer3
    destroy_layer2
    destroy_layer1
    print_success "All resources destroyed"
}

destroy_option4() {
    print_header "OPTION 4: Destroy Helm deployment (6→5→3→2→1)"
    print_warning "This will destroy ALL resources!"
    read -p "Type 'yes' to confirm: " confirm
    if [ "$confirm" != "yes" ]; then
        print_warning "Destroy cancelled"
        return
    fi
    destroy_layer6
    destroy_layer5
    destroy_layer3
    destroy_layer2
    destroy_layer1
    print_success "All resources destroyed"
}

# Show outputs
show_outputs() {
    print_header "DEPLOYMENT OUTPUTS"
    
    echo -e "${CYAN}Infrastructure Outputs:${NC}"
    cd 1-infrastructure
    terraform output
    cd ..
    
    echo ""
    echo -e "${CYAN}EKS Addons Outputs:${NC}"
    cd 2-eks-addons
    terraform output
    cd ..
    
    echo ""
    echo -e "${CYAN}Kubernetes Resources:${NC}"
    kubectl get all -n application
    
    echo ""
    echo -e "${CYAN}Ingress URLs:${NC}"
    kubectl get ingress -n application
    
    echo ""
    echo -e "${CYAN}Monitoring Services:${NC}"
    kubectl get svc -n monitoring
    
    echo ""
    print_success "Deployment completed successfully!"
    echo ""
    echo "Access your application:"
    echo "  Frontend: kubectl get ingress frontend-ingress -n application"
    echo "  Backend:  kubectl get ingress backend-ingress -n application"
    echo ""
    echo "Access monitoring:"
    echo "  Grafana:  kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80"
    echo "  Kibana:   kubectl get svc -n monitoring kibana-kibana"
    echo ""
}

# ============================================================================
# MAIN MENU
# ============================================================================

show_menu() {
    clear
    echo -e "${BLUE}=========================================="
    echo "  ShopEase Deployment Manager"
    echo "==========================================${NC}"
    echo ""
    echo -e "${GREEN}DEPLOYMENT OPTIONS:${NC}"
    echo "  1) Deploy with kubectl (1→2→3→4→6)"
    echo "  2) Deploy with Helm (1→2→3→5→6)"
    echo ""
    echo -e "${RED}DESTROY OPTIONS:${NC}"
    echo "  3) Destroy kubectl deployment (6→4→3→2→1)"
    echo "  4) Destroy Helm deployment (6→5→3→2→1)"
    echo ""
    echo -e "${YELLOW}INDIVIDUAL LAYERS:${NC}"
    echo "  5) Layer 1: Infrastructure (VPC, IAM, EKS, Bastion)"
    echo "  6) Layer 2: EKS Addons (OIDC, ALB Controller, Autoscaler, etc.)"
    echo "  7) Layer 3: Docker Images (Build & Push to ECR)"
    echo "  8) Layer 4: Kubernetes Manifests (kubectl apply)"
    echo "  9) Layer 5: Helm Chart (helm install)"
    echo "  10) Layer 6: Monitoring (Prometheus, Grafana, ELK)"
    echo ""
    echo -e "${CYAN}UTILITIES:${NC}"
    echo "  11) Show outputs"
    echo "  12) Check prerequisites"
    echo "  0) Exit"
    echo ""
    echo -n "Enter your choice: "
}

# ============================================================================
# MAIN SCRIPT
# ============================================================================

main() {
    while true; do
        show_menu
        read choice
        
        case $choice in
            1)
                deploy_option1
                ;;
            2)
                deploy_option2
                ;;
            3)
                destroy_option3
                ;;
            4)
                destroy_option4
                ;;
            5)
                check_prerequisites
                deploy_layer1
                ;;
            6)
                check_prerequisites
                deploy_layer2
                ;;
            7)
                check_prerequisites
                deploy_layer3
                ;;
            8)
                check_prerequisites
                deploy_layer4
                ;;
            9)
                check_prerequisites
                deploy_layer5
                ;;
            10)
                check_prerequisites
                deploy_layer6
                ;;
            11)
                show_outputs
                ;;
            12)
                check_prerequisites
                ;;
            0)
                echo ""
                echo "Exiting..."
                exit 0
                ;;
            *)
                print_error "Invalid option. Please try again."
                sleep 2
                ;;
        esac
        
        echo ""
        read -p "Press Enter to continue..."
    done
}

# Run main
main
