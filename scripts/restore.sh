#!/bin/bash

# Restore script for DIGIT HCM
set -e

ENVIRONMENT=$1
BACKUP_TIMESTAMP=$2

if [ -z "$ENVIRONMENT" ] || [ -z "$BACKUP_TIMESTAMP" ]; then
    echo "Usage: $0 <environment> <backup-timestamp>"
    exit 1
fi

echo "Restoring $ENVIRONMENT from backup $BACKUP_TIMESTAMP..."

# Download backup from S3
aws s3 cp s3://digit-hcm-backups/$ENVIRONMENT/$BACKUP_TIMESTAMP.tar.gz /tmp/
tar -xzf /tmp/$BACKUP_TIMESTAMP.tar.gz -C /tmp/

# Restore database
echo "Restoring database..."
PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -U $DB_USERNAME -d $DB_NAME < /tmp/database.sql

# Restore Kubernetes resources
echo "Restoring Kubernetes resources..."
kubectl apply -f /tmp/kubernetes-resources.yaml
kubectl apply -f /tmp/configmaps.yaml
kubectl apply -f /tmp/secrets.yaml

# Cleanup
rm -rf /tmp/$BACKUP_TIMESTAMP*

echo "Restore completed successfully!"