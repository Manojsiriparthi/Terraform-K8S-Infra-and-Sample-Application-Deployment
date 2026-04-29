#!/bin/bash

# ============================================================================
# PREREQUISITES CHECK AND INSTALLATION SCRIPT
# Automatically installs missing tools and validates setup
# ============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Detect OS
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if [ -f /etc/os-release ]; then
            . /etc/os-release
            OS=$ID
        else
            OS="linux"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
    else
        OS="unknown"
    fi
    echo $OS
}

OS=$(detect_os)

echo -e "${BLUE}=========================================="
echo "ShopEase Prerequisites Setup"
echo "==========================================${NC}"
echo -e "${CYAN}Detected OS: $OS${NC}"
echo ""

MISSING_TOOLS=0

check_tool() {
    if command -v $1 &> /dev/null; then
        echo -e "${GREEN}✓${NC} $1 is installed"
        return 0
    else
        echo -e "${RED}✗${NC} $1 is NOT installed"
        MISSING_TOOLS=1
        return 1
    fi
}

echo "Checking required tools..."
echo ""

check_tool "terraform"
check_tool "aws"
check_tool "kubectl"
check_tool "helm"
check_tool "docker"
check_tool "jq"

echo ""
echo "=========================================="

if [ $MISSING_TOOLS -eq 1 ]; then
    echo -e "${CYAN}Installing missing tools...${NC}"
    echo ""
    
    case $OS in
        ubuntu|debian)
            echo -e "${CYAN}Updating package list...${NC}"
            sudo apt update
            
            # Install unzip if needed (required for AWS CLI)
            if ! command -v unzip &> /dev/null; then
                echo -e "${CYAN}Installing unzip...${NC}"
                sudo apt install -y unzip
            fi
            
            if ! command -v terraform &> /dev/null; then
                echo -e "${CYAN}Installing Terraform...${NC}"
                wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
                echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
                sudo apt update && sudo apt install -y terraform
                echo -e "${GREEN}✓ Terraform installed${NC}"
            fi
            
            if ! command -v aws &> /dev/null; then
                echo -e "${CYAN}Installing AWS CLI...${NC}"
                curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
                unzip -q awscliv2.zip
                sudo ./aws/install
                rm -rf aws awscliv2.zip
                echo -e "${GREEN}✓ AWS CLI installed${NC}"
            fi
            
            if ! command -v kubectl &> /dev/null; then
                echo -e "${CYAN}Installing kubectl...${NC}"
                curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
                sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
                rm kubectl
                echo -e "${GREEN}✓ kubectl installed${NC}"
            fi
            
            if ! command -v helm &> /dev/null; then
                echo -e "${CYAN}Installing Helm...${NC}"
                curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
                echo -e "${GREEN}✓ Helm installed${NC}"
            fi
            
            if ! command -v docker &> /dev/null; then
                echo -e "${CYAN}Installing Docker...${NC}"
                sudo apt install -y docker.io
                sudo systemctl start docker
                sudo systemctl enable docker
                sudo usermod -aG docker $USER
                echo -e "${GREEN}✓ Docker installed${NC}"
                echo -e "${YELLOW}Note: Run 'newgrp docker' or log out/in for Docker permissions${NC}"
            fi
            
            if ! command -v jq &> /dev/null; then
                echo -e "${CYAN}Installing jq...${NC}"
                sudo apt install -y jq
                echo -e "${GREEN}✓ jq installed${NC}"
            fi
            ;;
            
        rhel|centos|fedora|amzn)
            if ! command -v terraform &> /dev/null; then
                echo -e "${CYAN}Installing Terraform...${NC}"
                sudo yum install -y yum-utils
                sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
                sudo yum install -y terraform
                echo -e "${GREEN}✓ Terraform installed${NC}"
            fi
            
            if ! command -v aws &> /dev/null; then
                echo -e "${CYAN}Installing AWS CLI...${NC}"
                curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
                unzip -q awscliv2.zip
                sudo ./aws/install
                rm -rf aws awscliv2.zip
                echo -e "${GREEN}✓ AWS CLI installed${NC}"
            fi
            
            if ! command -v kubectl &> /dev/null; then
                echo -e "${CYAN}Installing kubectl...${NC}"
                curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
                sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
                rm kubectl
                echo -e "${GREEN}✓ kubectl installed${NC}"
            fi
            
            if ! command -v helm &> /dev/null; then
                echo -e "${CYAN}Installing Helm...${NC}"
                curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
                echo -e "${GREEN}✓ Helm installed${NC}"
            fi
            
            if ! command -v docker &> /dev/null; then
                echo -e "${CYAN}Installing Docker...${NC}"
                sudo yum install -y docker
                sudo systemctl start docker
                sudo systemctl enable docker
                sudo usermod -aG docker $USER
                echo -e "${GREEN}✓ Docker installed${NC}"
            fi
            
            if ! command -v jq &> /dev/null; then
                echo -e "${CYAN}Installing jq...${NC}"
                sudo yum install -y jq
                echo -e "${GREEN}✓ jq installed${NC}"
            fi
            ;;
            
        macos)
            echo -e "${YELLOW}Automatic installation not supported for macOS${NC}"
            echo "Please run these commands manually:"
            echo ""
            echo "brew install terraform awscli kubectl helm jq"
            echo "brew install --cask docker"
            exit 1
            ;;
            
        *)
            echo -e "${RED}Automatic installation not supported for this OS${NC}"
            echo "Please install manually from:"
            echo "  https://developer.hashicorp.com/terraform/downloads"
            echo "  https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html"
            echo "  https://kubernetes.io/docs/tasks/tools/"
            echo "  https://helm.sh/docs/intro/install/"
            echo "  https://docs.docker.com/get-docker/"
            exit 1
            ;;
    esac
fi

echo ""
echo -e "${GREEN}=========================================="
echo "✓ All tools installed successfully!"
echo "==========================================${NC}"
echo ""

# Print all versions
echo -e "${CYAN}Installed versions:${NC}"
echo ""
terraform version | head -n 1
aws --version
kubectl version --client --short 2>/dev/null || kubectl version --client 2>&1 | head -n 1
helm version --short
docker --version
jq --version

echo ""
echo "=========================================="
echo ""

echo "Checking AWS credentials..."
if aws sts get-caller-identity &> /dev/null; then
    echo -e "${GREEN}✓${NC} AWS credentials configured"
    ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    CALLER_ARN=$(aws sts get-caller-identity --query Arn --output text)
    echo "  Account ID: $ACCOUNT_ID"
    echo "  Identity: $CALLER_ARN"
else
    echo -e "${YELLOW}⚠${NC} AWS credentials NOT configured"
    echo ""
    echo "  Option 1: Run 'aws configure' with access keys"
    echo "  Option 2: Attach IAM role to this EC2 instance (recommended)"
    echo ""
    echo -e "${CYAN}Required IAM permissions:${NC}"
    echo "  - EC2, VPC, EKS, IAM, ECR, CloudWatch, S3"
fi

echo ""
echo -e "${GREEN}✓ Setup completed!${NC}"
echo -e "${CYAN}Ready to deploy: ./8-scripts/run.sh${NC}"
echo ""
