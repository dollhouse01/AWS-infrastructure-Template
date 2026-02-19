#!/bin/bash

# Backup script for DIGIT HCM
set -e

ENVIRONMENT=$1
if [ -z "$ENVIRONMENT" ]; then
    echo "Usage: $0 <environment>"
    exit 1
fi

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/tmp/backups/$ENVIRONMENT/$TIMESTAMP"
mkdir -p $BACKUP_DIR

echo "Starting backup for $ENVIRONMENT environment..."

# Backup RDS database
echo "Backing up RDS database..."
PGPASSWORD=$DB_PASSWORD pg_dump -h $DB_HOST -U $DB_USERNAME -d $DB_NAME > $BACKUP_DIR/database.sql

# Backup Kubernetes resources
echo "Backing up Kubernetes resources..."
kubectl get all -n digit-hcm -o yaml > $BACKUP_DIR/kubernetes-resources.yaml
kubectl get configmaps -n digit-hcm -o yaml > $BACKUP_DIR/configmaps.yaml
kubectl get secrets -n digit-hcm -o yaml > $BACKUP_DIR/secrets.yaml

# Compress backup
tar -czf $BACKUP_DIR.tar.gz -C $BACKUP_DIR .

# Upload to S3
aws s3 cp $BACKUP_DIR.tar.gz s3://digit-hcm-backups/$ENVIRONMENT/$TIMESTAMP/

# Cleanup
rm -rf $BACKUP_DIR $BACKUP_DIR.tar.gz

echo "Backup completed successfully: $TIMESTAMP"