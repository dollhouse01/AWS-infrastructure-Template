#!/bin/bash

# Promote from dev to uat
set -e

echo "Promoting dev to uat..."

# Get current dev image tags
DEV_BACKEND_IMAGE=$(kubectl get deployment -n digit-hcm digit-hcm-backend -o jsonpath='{.spec.template.spec.containers[0].image}')
DEV_FRONTEND_IMAGE=$(kubectl get deployment -n digit-hcm digit-hcm-frontend -o jsonpath='{.spec.template.spec.containers[0].image}')
DEV_WORKER_IMAGE=$(kubectl get deployment -n digit-hcm digit-hcm-worker -o jsonpath='{.spec.template.spec.containers[0].image}')

# Tag images for UAT
BACKEND_TAG=$(echo $DEV_BACKEND_IMAGE | cut -d':' -f2)
FRONTEND_TAG=$(echo $DEV_FRONTEND_IMAGE | cut -d':' -f2)
WORKER_TAG=$(echo $DEV_WORKER_IMAGE | cut -d':' -f2)

# Deploy to UAT
cd terraform/environments/uat
terraform workspace select uat
terraform apply -auto-approve

cd ../../../kubernetes

# Update UAT deployments
kubectl config use-context uat
kubectl set image deployment/digit-hcm-backend -n digit-hcm backend=$DEV_BACKEND_IMAGE
kubectl set image deployment/digit-hcm-frontend -n digit-hcm frontend=$DEV_FRONTEND_IMAGE
kubectl set image deployment/digit-hcm-worker -n digit-hcm worker=$DEV_WORKER_IMAGE

# Wait for rollout
kubectl rollout status deployment/digit-hcm-backend -n digit-hcm
kubectl rollout status deployment/digit-hcm-frontend -n digit-hcm
kubectl rollout status deployment/digit-hcm-worker -n digit-hcm

echo "Promotion to UAT completed!"