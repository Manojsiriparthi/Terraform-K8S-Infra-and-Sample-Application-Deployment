#!/bin/bash

# Test script to verify GPU configuration

echo "=== Checking dev.tfvars ==="
grep -A 5 "enable_gpu_nodes" 1-infrastructure/dev.tfvars

echo ""
echo "=== Checking prod.tfvars ==="
grep -A 5 "enable_gpu_nodes" 1-infrastructure/prod.tfvars

echo ""
echo "=== Checking variables.tf ==="
grep -A 3 "enable_gpu_nodes" 1-infrastructure/variables.tf

echo ""
echo "=== Checking modules/eks/variables.tf ==="
grep -A 3 "enable_gpu_nodes" 1-infrastructure/modules/eks/variables.tf

echo ""
echo "=== Checking modules/eks/main.tf GPU node group ==="
grep -A 2 "aws_eks_node_group.*gpu" 1-infrastructure/modules/eks/main.tf

echo ""
echo "=== Checking run.sh GPU logic ==="
grep -A 10 "GPU Node Configuration" run.sh
