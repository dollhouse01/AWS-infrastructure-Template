#!/bin/bash

# Initialize Terraform for all environments
set -e

echo "Initializing Terraform..."

# Create S3 bucket for Terraform state if it doesn't exist
BUCKET_NAME="digit-hcm-terraform-state"
if ! aws s3 ls "s3://$BUCKET_NAME" 2>&1 | grep -q 'NoSuchBucket'; then
    echo "Creating S3 bucket for Terraform state..."
    aws s3 mb s3://$BUCKET_NAME --region af-south-1
    aws s3api put-bucket-versioning --bucket $BUCKET_NAME --versioning-configuration Status=Enabled
    aws s3api put-bucket-encryption --bucket $BUCKET_NAME --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'
fi

# Create DynamoDB table for state locking if it doesn't exist
TABLE_NAME="terraform-state-lock"
if ! aws dynamodb describe-table --table-name $TABLE_NAME 2>&1 | grep -q 'ResourceNotFoundException'; then
    echo "Creating DynamoDB table for state locking..."
    aws dynamodb create-table \
        --table-name $TABLE_NAME \
        --attribute-definitions AttributeName=LockID,AttributeType=S \
        --key-schema AttributeName=LockID,KeyType=HASH \
        --billing-mode PAY_PER_REQUEST \
        --region af-south-1
fi

# Initialize each environment
for env in dev uat prod; do
    echo "Initializing $env environment..."
    cd terraform/environments/$env
    terraform init \
        -backend-config="bucket=$BUCKET_NAME" \
        -backend-config="key=$env/terraform.tfstate" \
        -backend-config="region=af-south-1" \
        -backend-config="dynamodb_table=$TABLE_NAME" \
        -backend-config="encrypt=true"
    cd -
done

echo "Terraform initialization complete!"