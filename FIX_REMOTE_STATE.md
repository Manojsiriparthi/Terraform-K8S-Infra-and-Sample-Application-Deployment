# Fix Remote State Issues

## What Was Wrong

1. **Remote state backend mismatch**: 2-eks-addons was looking for `local` backend but should use `s3`
2. **Unnecessary cluster_name variable**: Terraform was prompting for cluster_name manually
3. **State not in S3**: 1-infrastructure state might be local, not in S3

## What I Fixed

### ✅ Fixed 2-eks-addons/provider.tf
Changed from:
```hcl
data "terraform_remote_state" "infrastructure" {
  backend = "local"
  config = {
    path = "../1-infrastructure/terraform.tfstate"
  }
}
```

To:
```hcl
data "terraform_remote_state" "infrastructure" {
  backend = "s3"
  config = {
    bucket = "shopease-terraform-state"
    key    = "1-infrastructure/terraform.tfstate"
    region = "us-east-1"
  }
}
```

### ✅ Removed cluster_name variable
- Removed from `2-eks-addons/variables.tf`
- Now automatically fetched from remote state
- No more manual prompts!

## How to Fix the Deployment

### Step 1: Ensure 1-infrastructure state is in S3

Check if the state file exists in S3:
```bash
aws s3 ls s3://shopease-terraform-state/1-infrastructure/
```

**If you see the file**: Great! Skip to Step 2.

**If you DON'T see the file**: The state is still local. Upload it:

```bash
cd 1-infrastructure

# Copy local state to S3
terraform init -migrate-state

# This will ask: "Do you want to copy existing state to the new backend?"
# Answer: yes
```

### Step 2: Re-initialize 2-eks-addons

```bash
cd ../2-eks-addons

# Remove old terraform state
rm -rf .terraform .terraform.lock.hcl

# Re-initialize with new remote state config
terraform init

# Now it should work!
terraform plan
```

### Step 3: Deploy

```bash
terraform apply
```

## Verification

After Step 1, verify both state files are in S3:
```bash
aws s3 ls s3://shopease-terraform-state/
# Should show:
# 1-infrastructure/
# 2-eks-addons/

aws s3 ls s3://shopease-terraform-state/1-infrastructure/
# Should show: terraform.tfstate

aws s3 ls s3://shopease-terraform-state/2-eks-addons/
# Should show: terraform.tfstate (after first apply)
```

## Why This Happened

1. **1-infrastructure was deployed with S3 backend** but state might still be local
2. **2-eks-addons was configured to read local state** instead of S3
3. **Mismatch caused the error**: "Unable to find remote state"

## Now It Will Work

- ✅ No more manual cluster_name prompts
- ✅ Automatically reads from 1-infrastructure outputs
- ✅ Both layers use S3 backend consistently
- ✅ State is centralized and shareable

## Quick Fix Script

Run this to fix everything automatically:

```bash
#!/bin/bash

echo "Step 1: Migrate 1-infrastructure state to S3..."
cd 1-infrastructure
terraform init -migrate-state -force-copy
cd ..

echo "Step 2: Re-initialize 2-eks-addons..."
cd 2-eks-addons
rm -rf .terraform .terraform.lock.hcl
terraform init
cd ..

echo "✅ Done! Now run: cd 2-eks-addons && terraform apply"
```

Save this as `fix-state.sh`, make it executable, and run it:
```bash
chmod +x fix-state.sh
./fix-state.sh
```
