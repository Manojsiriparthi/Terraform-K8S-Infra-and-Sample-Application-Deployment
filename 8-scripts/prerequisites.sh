#!/bin/bash

# ============================================================================
# PREREQUISITES CHECK SCRIPT
# Validates all required tools before deployment
# ============================================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=========================================="
echo "ShopEase Prerequisites Check"
echo "==========================================${NC}"
echo ""

MISSING_TOOLS=0

check_tool() {
    if command -v $1 &> /dev/null; then
        echo -e "${GREEN}✓${NC} $1 is installed"
        if [ ! -z "$2" ]; then
            VERSION=$($1 $2 2>&1 | head -n 1)
            echo "  $VERSION"
        fi
    else
        echo -e "${RED}✗${NC} $1 is NOT installed"
        MISSING_TOOLS=1
    fi
}

echo "Checking required tools..."
echo ""

check_tool "terraform" "version"
check_tool "aws" "--version"
check_tool "kubectl" "version --client"
check_tool "helm" "version --short"
check_tool "docker" "--version"
check_tool "jq" "--version"

echo ""
echo "=========================================="

if [ $MISSING_TOOLS -eq 1 ]; then
    echo -e "${RED}ERROR: Missing required tools!${NC}"
    echo ""
    echo "Installation:"
    echo "  Terraform: https://developer.hashicorp.com/terraform/downloads"
    echo "  AWS CLI:   https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html"
    echo "  kubectl:   https://kubernetes.io/docs/tasks/tools/"
    echo "  Helm:      https://helm.sh/docs/intro/install/"
    echo "  Docker:    https://docs.docker.com/get-docker/"
    echo "  jq:        brew install jq"
    exit 1
fi

echo -e "${GREEN}✓ All tools installed${NC}"
echo ""

echo "Checking AWS credentials..."
if aws sts get-caller-identity &> /dev/null; then
    echo -e "${GREEN}✓${NC} AWS credentials configured"
    aws sts get-caller-identity
else
    echo -e "${RED}✗${NC} AWS credentials NOT configured"
    echo "Run: aws configure"
    exit 1
fi

echo ""
echo -e "${GREEN}✓ Prerequisites check passed!${NC}"
echo ""
