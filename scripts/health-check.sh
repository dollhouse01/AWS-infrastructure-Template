#!/bin/bash

# Health check script for DIGIT HCM
set -e

ENVIRONMENT=$1
if [ -z "$ENVIRONMENT" ]; then
    echo "Usage: $0 <environment>"
    exit 1
fi

echo "Running health checks for $ENVIRONMENT environment..."

# Check EKS cluster
echo "Checking EKS cluster..."
aws eks describe-cluster --name digit-hcm-$ENVIRONMENT --region af-south-1

# Check RDS
echo "Checking RDS..."
aws rds describe-db-instances --db-instance-identifier digit-hcm-$ENVIRONMENT --region af-south-1

# Check ElastiCache
echo "Checking ElastiCache..."
aws elasticache describe-replication-groups --replication-group-id digit-redis-$ENVIRONMENT --region af-south-1

# Check MSK
echo "Checking MSK..."
aws kafka describe-cluster --cluster-arn $(aws kafka list-clusters --region af-south-1 --query "ClusterInfoList[?ClusterName=='digit-kafka-$ENVIRONMENT'].ClusterArn" --output text) --region af-south-1

# Check Kubernetes pods
echo "Checking Kubernetes pods..."
kubectl get pods -n digit-hcm

# Check application health endpoints
API_URL=$(aws ssm get-parameter --name "/$ENVIRONMENT/loadbalancer/dns" --query "Parameter.Value" --output text)
curl -f http://$API_URL/health || exit 1

echo "All health checks passed!"