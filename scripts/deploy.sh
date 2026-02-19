#!/bin/bash

# Deployment script for DIGIT HCM
set -e

ENVIRONMENT=$1
if [ -z "$ENVIRONMENT" ]; then
    echo "Usage: $0 <environment>"
    exit 1
fi

echo "Deploying DIGIT HCM to $ENVIRONMENT environment..."

# Configure kubectl
./scripts/configure-kubectl.sh $ENVIRONMENT

# Apply Kubernetes manifests
kubectl apply -f kubernetes/digit/namespace.yaml

# Substitute environment variables in config files
envsubst < kubernetes/digit/configmap.yaml | kubectl apply -f -
envsubst < kubernetes/digit/secrets.yaml | kubectl apply -f -
kubectl apply -f kubernetes/digit/service-account.yaml
kubectl apply -f kubernetes/digit/pvc.yaml

# Deploy applications
kubectl apply -f kubernetes/digit/deployments/
kubectl apply -f kubernetes/digit/services/
kubectl apply -f kubernetes/digit/hpa.yaml
kubectl apply -f kubernetes/digit/pod-disruption-budget.yaml
kubectl apply -f kubernetes/digit/ingress.yaml

# Wait for deployments to be ready
kubectl -n digit-hcm rollout status deployment/digit-hcm-backend
kubectl -n digit-hcm rollout status deployment/digit-hcm-frontend
kubectl -n digit-hcm rollout status deployment/digit-hcm-worker

echo "Deployment to $ENVIRONMENT completed successfully!"