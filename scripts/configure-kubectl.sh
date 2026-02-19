#!/bin/bash

# Configure kubectl for EKS cluster
set -e

ENVIRONMENT=$1
if [ -z "$ENVIRONMENT" ]; then
    echo "Usage: $0 <environment>"
    exit 1
fi

echo "Configuring kubectl for $ENVIRONMENT environment..."

# Get cluster name from Terraform output
cd terraform/environments/$ENVIRONMENT
CLUSTER_NAME=$(terraform output -raw eks_cluster_name)

# Update kubeconfig
aws eks update-kubeconfig --region af-south-1 --name $CLUSTER_NAME

# Verify connection
kubectl get nodes

echo "kubectl configured successfully for $ENVIRONMENT!"