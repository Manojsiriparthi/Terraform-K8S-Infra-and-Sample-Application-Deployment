#!/bin/bash

# ============================================================================
# DEPLOYMENT AUTOMATION SCRIPT
# ============================================================================
# Interactive script to deploy/destroy infrastructure and applications
# Handles folders 1-5 (not Jenkins folder 6)
#
# PREREQUISITES:
# - AWS CLI configured with credentials
# - Terraform installed
# - Docker installed
# - kubectl installed
# - Helm installed
#
# USAGE:
#   chmod +x run.sh
#   ./run.sh
# ============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}============================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}============================================${NC}"
}

# Function to get AWS account info
get_aws_info() {
    export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    export AWS_REGION=$(aws configure get region || echo "us-east-1")
    export ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
    
    print_info "AWS Account ID: ${AWS_ACCOUNT_ID}"
    print_info "AWS Region: ${AWS_REGION}"
    print_info "ECR Registry: ${ECR_REGISTRY}"
}

# Function 1: Apply Infrastructure (Folder 1 + Folder 2)
apply_infrastructure() {
    print_header "OPTION 1: Apply Infrastructure (Folders 1 & 2)"
    
    # Get AWS info first
    get_aws_info
    
    echo ""
    echo "Select tfvars file:"
    echo "1) dev.tfvars"
    echo "2) prod.tfvars"
    read -p "Enter choice [1-2]: " tfvars_choice
    
    case $tfvars_choice in
        1) TFVARS_FILE="dev.tfvars"; ENVIRONMENT="dev" ;;
        2) TFVARS_FILE="prod.tfvars"; ENVIRONMENT="prod" ;;
        *) print_error "Invalid choice"; exit 1 ;;
    esac
    
    print_info "Using: ${TFVARS_FILE}"
    print_info "Environment: ${ENVIRONMENT}"
    
    # Folder 1: Infrastructure
    print_info "Step 1/2: Deploying 1-infrastructure..."
    cd 1-infrastructure
    
    terraform init
    terraform plan -var-file="${TFVARS_FILE}" -out=tfplan
    
    read -p "Apply Terraform for infrastructure? (yes/no): " confirm
    if [ "$confirm" != "yes" ]; then
        print_warn "Aborted by user"
        cd ..
        return
    fi
    
    terraform apply tfplan
    
    # Get cluster name from output
    CLUSTER_NAME=$(terraform output -raw cluster_name)
    print_info "Cluster Name: ${CLUSTER_NAME}"
    
    cd ..
    
    # Folder 2: EKS Addons
    print_info "Step 2/2: Deploying 2-eks-addons..."
    cd 2-eks-addons
    
    terraform init
    terraform plan -var-file="terraform.tfvars" -out=tfplan
    
    read -p "Apply Terraform for addons? (yes/no): " confirm
    if [ "$confirm" != "yes" ]; then
        print_warn "Aborted by user"
        cd ..
        return
    fi
    
    terraform apply tfplan
    
    cd ..
    
    # Update kubeconfig
    print_info "Updating kubeconfig..."
    aws eks update-kubeconfig --region ${AWS_REGION} --name ${CLUSTER_NAME}
    
    print_info "✅ Infrastructure deployment complete!"
    kubectl get nodes
}

# Function 2: Destroy Infrastructure (Folder 2 then Folder 1)
destroy_infrastructure() {
    print_header "OPTION 2: Destroy Infrastructure (Folders 2 & 1)"
    
    print_warn "⚠️  WARNING: This will destroy all infrastructure!"
    read -p "Are you sure? Type 'destroy' to confirm: " confirm
    if [ "$confirm" != "destroy" ]; then
        print_warn "Aborted by user"
        return
    fi
    
    echo ""
    echo "Select tfvars file that was used:"
    echo "1) dev.tfvars"
    echo "2) prod.tfvars"
    read -p "Enter choice [1-2]: " tfvars_choice
    
    case $tfvars_choice in
        1) TFVARS_FILE="dev.tfvars"; ENVIRONMENT="dev" ;;
        2) TFVARS_FILE="prod.tfvars"; ENVIRONMENT="prod" ;;
        *) print_error "Invalid choice"; return ;;
    esac
    
    print_info "Using: ${TFVARS_FILE}"
    
    # Folder 2: EKS Addons (destroy first)
    print_info "Step 1/2: Destroying 2-eks-addons..."
    cd 2-eks-addons
    
    terraform init
    terraform destroy -auto-approve -var-file="terraform.tfvars"
    
    cd ..
    
    # Folder 1: Infrastructure (destroy last)
    print_info "Step 2/2: Destroying 1-infrastructure..."
    cd 1-infrastructure
    
    terraform init
    terraform destroy -auto-approve -var-file="${TFVARS_FILE}"
    
    cd ..
    
    print_info "✅ Infrastructure destruction complete!"
}

# Function 3: Build Docker Images and Update Folder 4
build_docker_images() {
    print_header "OPTION 3: Build Docker Images & Update Folder 4"
    
    get_aws_info
    
    echo ""
    echo "Select environment:"
    echo "1) dev"
    echo "2) prod"
    read -p "Enter choice [1-2]: " env_choice
    
    case $env_choice in
        1) ENVIRONMENT="dev" ;;
        2) ENVIRONMENT="prod" ;;
        *) print_error "Invalid choice"; return ;;
    esac
    
    # Generate image tag
    GIT_COMMIT=$(git rev-parse --short HEAD 2>/dev/null || echo "latest")
    IMAGE_TAG="${GIT_COMMIT}"
    ECR_PREFIX="shopease-${ENVIRONMENT}"
    
    print_info "Environment: ${ENVIRONMENT}"
    print_info "Image Tag: ${IMAGE_TAG}"
    print_info "ECR Prefix: ${ECR_PREFIX}"
    
    # Login to ECR
    print_info "Logging into ECR..."
    aws ecr get-login-password --region ${AWS_REGION} | \
        docker login --username AWS --password-stdin ${ECR_REGISTRY}
    
    # Function to create ECR repository if it doesn't exist
    create_ecr_repo() {
        local repo_name=$1
        if ! aws ecr describe-repositories --repository-names ${repo_name} --region ${AWS_REGION} >/dev/null 2>&1; then
            print_info "Creating ECR repository: ${repo_name}"
            aws ecr create-repository \
                --repository-name ${repo_name} \
                --region ${AWS_REGION} \
                --image-scanning-configuration scanOnPush=true \
                --encryption-configuration encryptionType=AES256 \
                --tags Key=Environment,Value=${ENVIRONMENT} Key=ManagedBy,Value=Terraform
        else
            print_info "ECR repository already exists: ${repo_name}"
        fi
    }
    
    # Find all Dockerfiles in 3-application
    print_info "Finding all Dockerfiles in 3-application..."
    
    # Backend services
    BACKEND_SERVICES="adservice cartservice checkoutservice currencyservice emailservice paymentservice productcatalogservice recommendationservice shippingservice"
    
    for service in $BACKEND_SERVICES; do
        SERVICE_DIR="3-application/backend/services/${service}"
        REPO_NAME="${ECR_PREFIX}-${service}"
        
        if [ -f "${SERVICE_DIR}/Dockerfile" ]; then
            # Create ECR repository if needed
            create_ecr_repo ${REPO_NAME}
            
            print_info "Building ${service}..."
            docker build -t ${ECR_REGISTRY}/${REPO_NAME}:${IMAGE_TAG} \
                         -t ${ECR_REGISTRY}/${REPO_NAME}:latest \
                         ${SERVICE_DIR}
            
            print_info "Pushing ${service} to ECR..."
            docker push ${ECR_REGISTRY}/${REPO_NAME}:${IMAGE_TAG}
            docker push ${ECR_REGISTRY}/${REPO_NAME}:latest
        else
            print_warn "Dockerfile not found for ${service}"
        fi
    done
    
    # Frontend
    FRONTEND_DIR="3-application/frontend"
    FRONTEND_REPO="${ECR_PREFIX}-frontend"
    
    if [ -f "${FRONTEND_DIR}/Dockerfile" ]; then
        # Create ECR repository if needed
        create_ecr_repo ${FRONTEND_REPO}
        
        print_info "Building frontend..."
        docker build -t ${ECR_REGISTRY}/${FRONTEND_REPO}:${IMAGE_TAG} \
                     -t ${ECR_REGISTRY}/${FRONTEND_REPO}:latest \
                     ${FRONTEND_DIR}
        
        print_info "Pushing frontend to ECR..."
        docker push ${ECR_REGISTRY}/${FRONTEND_REPO}:${IMAGE_TAG}
        docker push ${ECR_REGISTRY}/${FRONTEND_REPO}:latest
    fi
    
    # Update 4-kubernetes-manifests with new image tags
    print_info "Updating 4-kubernetes-manifests with image tags..."
    cd 4-kubernetes-manifests
    
    # Create backup
    cp backend-all.yaml backend-all.yaml.bak 2>/dev/null || true
    cp frontend.yaml frontend.yaml.bak 2>/dev/null || true
    
    # Update image references
    sed -i.tmp "s|<AWS_ACCOUNT_ID>|${AWS_ACCOUNT_ID}|g" backend-all.yaml
    sed -i.tmp "s|<REGION>|${AWS_REGION}|g" backend-all.yaml
    sed -i.tmp "s|shopease-[a-z]*-|${ECR_PREFIX}-|g" backend-all.yaml
    sed -i.tmp "s|:[a-z0-9]*$|:${IMAGE_TAG}|g" backend-all.yaml
    
    sed -i.tmp "s|<AWS_ACCOUNT_ID>|${AWS_ACCOUNT_ID}|g" frontend.yaml
    sed -i.tmp "s|<REGION>|${AWS_REGION}|g" frontend.yaml
    sed -i.tmp "s|shopease-[a-z]*-|${ECR_PREFIX}-|g" frontend.yaml
    sed -i.tmp "s|:[a-z0-9]*$|:${IMAGE_TAG}|g" frontend.yaml
    
    rm -f *.tmp
    
    cd ..
    
    print_info "✅ Docker images built and pushed to ECR!"
    print_info "✅ Folder 4 manifests updated with tag: ${IMAGE_TAG}"
}

# Function 4: Install Kubernetes (Folder 4) and Monitoring (Folder 5)
install_kubernetes() {
    print_header "OPTION 4: Install Kubernetes (Folders 4 & 5)"
    
    # Deploy Folder 4: Kubernetes Manifests
    print_info "Step 1/2: Deploying 4-kubernetes-manifests..."
    cd 4-kubernetes-manifests
    
    # Deploy in order
    print_info "Creating namespace..."
    kubectl apply -f namespace.yaml
    
    print_info "Deploying database..."
    kubectl apply -f database.yaml
    kubectl wait --for=condition=ready pod -l app=postgres -n application --timeout=300s || true
    
    print_info "Deploying redis..."
    kubectl apply -f redis.yaml
    kubectl wait --for=condition=ready pod -l app=redis-cart -n application --timeout=120s || true
    
    print_info "Deploying backend services..."
    kubectl apply -f backend-all.yaml
    kubectl wait --for=condition=ready pod -l tier=backend -n application --timeout=300s || true
    
    print_info "Deploying frontend..."
    kubectl apply -f frontend.yaml
    kubectl wait --for=condition=ready pod -l app=frontend -n application --timeout=120s || true
    
    print_info "Deploying ingresses..."
    kubectl apply -f frontend-ingress-external.yaml
    kubectl apply -f backend-ingress-internal.yaml
    kubectl apply -f monitoring-ingress-internal.yaml
    
    print_info "Deploying security and scaling..."
    kubectl apply -f network-policies.yaml
    kubectl apply -f hpa.yaml
    kubectl apply -f servicemonitor.yaml
    
    cd ..
    
    print_info "✅ Folder 4 deployment complete!"
    
    # Deploy Folder 5: Monitoring
    print_info "Step 2/2: Deploying 5-monitoring..."
    cd 5-monitoring
    
    if [ -f "deploy.sh" ]; then
        print_info "Running monitoring deployment script..."
        chmod +x deploy.sh
        ./deploy.sh
    else
        print_warn "No deploy.sh found in 5-monitoring, skipping..."
    fi
    
    cd ..
    
    print_info "✅ Kubernetes and Monitoring installation complete!"
    
    # Show status
    echo ""
    print_info "Deployment Status:"
    kubectl get pods -n application
    echo ""
    kubectl get svc -n application
    echo ""
    kubectl get ingress -n application
}

# Function 5: Delete Monitoring (Folder 5) and Kubernetes (Folder 4)
delete_kubernetes() {
    print_header "OPTION 5: Delete Monitoring & Kubernetes (Folders 5 & 4)"
    
    print_warn "⚠️  WARNING: This will delete all application and monitoring resources!"
    read -p "Are you sure? (yes/no): " confirm
    if [ "$confirm" != "yes" ]; then
        print_warn "Aborted by user"
        return
    fi
    
    # Delete Folder 5: Monitoring (delete first)
    print_info "Step 1/2: Deleting 5-monitoring..."
    
    # Delete monitoring resources
    kubectl delete namespace monitoring --ignore-not-found=true
    
    print_info "✅ Folder 5 deleted!"
    
    # Delete Folder 4: Kubernetes Manifests (delete last)
    print_info "Step 2/2: Deleting 4-kubernetes-manifests..."
    cd 4-kubernetes-manifests
    
    # Delete in reverse order
    kubectl delete -f servicemonitor.yaml --ignore-not-found=true
    kubectl delete -f hpa.yaml --ignore-not-found=true
    kubectl delete -f network-policies.yaml --ignore-not-found=true
    kubectl delete -f monitoring-ingress-internal.yaml --ignore-not-found=true
    kubectl delete -f backend-ingress-internal.yaml --ignore-not-found=true
    kubectl delete -f frontend-ingress-external.yaml --ignore-not-found=true
    kubectl delete -f frontend.yaml --ignore-not-found=true
    kubectl delete -f backend-all.yaml --ignore-not-found=true
    kubectl delete -f redis.yaml --ignore-not-found=true
    kubectl delete -f database.yaml --ignore-not-found=true
    kubectl delete -f namespace.yaml --ignore-not-found=true
    
    cd ..
    
    print_info "✅ Kubernetes and Monitoring deletion complete!"
}

# Function 6: Show Outputs
show_outputs() {
    print_header "OPTION 6: Show Outputs"
    
    echo ""
    print_info "=== Infrastructure Outputs ==="
    cd 1-infrastructure
    if [ -f "terraform.tfstate" ]; then
        terraform output
    else
        print_warn "No Terraform state found in 1-infrastructure"
    fi
    cd ..
    
    echo ""
    print_info "=== EKS Addons Outputs ==="
    cd 2-eks-addons
    if [ -f "terraform.tfstate" ]; then
        terraform output
    else
        print_warn "No Terraform state found in 2-eks-addons"
    fi
    cd ..
    
    echo ""
    print_info "=== Kubernetes Resources ==="
    kubectl get nodes 2>/dev/null || print_warn "Cannot connect to cluster"
    echo ""
    kubectl get pods -n application 2>/dev/null || print_warn "No pods in application namespace"
    echo ""
    kubectl get svc -n application 2>/dev/null || print_warn "No services in application namespace"
    echo ""
    kubectl get ingress -n application 2>/dev/null || print_warn "No ingresses in application namespace"
    
    echo ""
    print_info "=== Monitoring Resources ==="
    kubectl get pods -n monitoring 2>/dev/null || print_warn "No pods in monitoring namespace"
    
    echo ""
    print_info "=== Frontend URL ==="
    kubectl get ingress frontend-ingress -n application \
        -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || print_warn "Frontend ingress not found"
    echo ""
}

# Main menu
show_menu() {
    clear
    print_header "DEPLOYMENT AUTOMATION SCRIPT"
    echo ""
    echo "Select an option:"
    echo ""
    echo "  1) Apply Infrastructure (Folders 1 & 2) - asks dev/prod tfvars"
    echo "  2) Destroy Infrastructure (Folders 2 & 1) - reverse order"
    echo "  3) Build Docker Images & Update Folder 4 - creates ECR images"
    echo "  4) Install Kubernetes & Monitoring (Folders 4 & 5)"
    echo "  5) Delete Monitoring & Kubernetes (Folders 5 & 4) - reverse order"
    echo "  6) Show Outputs (All folders)"
    echo "  7) Exit"
    echo ""
}

# Main script
main() {
    while true; do
        show_menu
        read -p "Enter your choice [1-7]: " choice
        
        case $choice in
            1) apply_infrastructure ;;
            2) destroy_infrastructure ;;
            3) build_docker_images ;;
            4) install_kubernetes ;;
            5) delete_kubernetes ;;
            6) show_outputs ;;
            7) print_info "Exiting..."; exit 0 ;;
            *) print_error "Invalid option. Please try again." ;;
        esac
        
        echo ""
        read -p "Press Enter to continue..."
    done
}

# Run main function
main
