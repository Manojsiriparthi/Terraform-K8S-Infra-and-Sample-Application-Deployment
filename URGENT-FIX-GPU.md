# URGENT: Fix GPU Node Creation Issue

## Problem
GPU nodes are being created even when using dev.tfvars because:
1. `enable_gpu_nodes = false` was missing from dev.tfvars
2. The module has `default = true` so it creates GPU nodes by default

## Solution Applied

### 1. Updated dev.tfvars
Added `enable_gpu_nodes = false` explicitly:
```hcl
# GPU Node Group
enable_gpu_nodes = false  # ← ADDED THIS LINE
```

### 2. run.sh Script Override
The script asks about GPU and overrides the tfvars value:
```bash
terraform plan -var-file="${TFVARS_FILE}" \
    -var="enable_gpu_nodes=${ENABLE_GPU}" \
    -var="gpu_node_desired_size=${GPU_DESIRED_SIZE}" \
    -out=tfplan
```

---

## How to Fix Current Deployment

### Step 1: Cancel Current Apply
```bash
# Press Ctrl+C to stop the current terraform apply
Ctrl+C
```

### Step 2: Destroy GPU Node Group
```bash
cd 1-infrastructure

# Destroy the GPU node group that's being created
terraform destroy \
    -target=module.eks.aws_eks_node_group.gpu \
    -var-file="dev.tfvars" \
    -var="enable_gpu_nodes=false"
```

### Step 3: Apply Again with Fixed Configuration
```bash
cd ..
./run.sh

# When prompted:
# 1. Select: 1 (Apply Infrastructure)
# 2. Tfvars: 1 (dev.tfvars)
# 3. GPU nodes: no
# 4. Confirm: yes
```

---

## Verification

After applying, verify GPU nodes are NOT created:

```bash
# Check Terraform state
cd 1-infrastructure
terraform state list | grep gpu
# Should show nothing or show but with count=0

# Check actual nodes
kubectl get nodes
# Should only show general and database nodes

# Check node count
kubectl get nodes --no-headers | wc -l
# Should be 4 nodes (2 general + 2 database)
```

---

## Why This Happened

1. **Module Default**: `modules/eks/variables.tf` has `default = true` for `enable_gpu_nodes`
2. **Missing in dev.tfvars**: dev.tfvars didn't have `enable_gpu_nodes = false`
3. **Terraform Behavior**: When a variable is not in tfvars, Terraform uses the module default
4. **Result**: GPU nodes were created even though other GPU variables were commented out

---

## Files Changed

✅ `1-infrastructure/dev.tfvars` - Added `enable_gpu_nodes = false`
✅ `run.sh` - Already has GPU override logic

---

## Quick Commands

```bash
# Cancel current apply
Ctrl+C

# Destroy GPU nodes
cd 1-infrastructure
terraform destroy -target=module.eks.aws_eks_node_group.gpu -var-file="dev.tfvars" -var="enable_gpu_nodes=false"

# Apply again
cd ..
./run.sh
# Select: 1 → 1 (dev) → no (GPU) → yes (confirm)
```

---

## Cost Impact

**Before Fix:**
- General: $100/month
- Database: $50/month
- GPU: $390/month
- **Total: $540/month**

**After Fix:**
- General: $100/month
- Database: $50/month
- GPU: $0/month
- **Total: $150/month**

**Savings: $390/month (72%)**

---

## Summary

✅ Added `enable_gpu_nodes = false` to dev.tfvars
✅ run.sh script can override this value
✅ GPU nodes will NOT be created in dev by default
✅ You can still enable GPU by answering "yes" when prompted

**Action Required:** Cancel current apply and restart with fixed configuration!
