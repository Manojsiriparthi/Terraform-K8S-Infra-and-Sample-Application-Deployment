#!/bin/bash

set -e

echo "=========================================="
echo "Fixing Remote State Configuration"
echo "=========================================="
echo ""

# Step 1: Check if 1-infrastructure state is in S3
echo "Step 1: Checking 1-infrastructure state in S3..."
if aws s3 ls s3://shopease-terraform-state/1-infrastructure/terraform.tfstate 2>/dev/null; then
    echo "✅ State file already in S3"
else
    echo "⚠️  State file not in S3. Migrating..."
    cd 1-infrastructure
    terraform init -migrate-state -force-copy
    cd ..
    echo "✅ State migrated to S3"
fi

echo ""

# Step 2: Re-initialize 2-eks-addons
echo "Step 2: Re-initializing 2-eks-addons..."
cd 2-eks-addons
rm -rf .terraform .terraform.lock.hcl
terraform init
cd ..

echo ""
echo "=========================================="
echo "✅ All Fixed!"
echo "=========================================="
echo ""
echo "Now run:"
echo "  cd 2-eks-addons"
echo "  terraform plan"
echo "  terraform apply"
echo ""
