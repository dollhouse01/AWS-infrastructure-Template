#!/bin/bash

# Script to generate Terraform documentation
set -e

echo "Generating Terraform documentation..."

# Check if terraform-docs is installed
if ! command -v terraform-docs &> /dev/null; then
    echo "terraform-docs could not be found. Please install it first."
    echo "Visit: https://github.com/terraform-docs/terraform-docs"
    exit 1
fi

# Generate docs for modules
for module in terraform/modules/*; do
    if [ -d "$module" ]; then
        echo "Generating docs for module: $(basename $module)"
        terraform-docs -c .terraform-docs.yml "$module"
    fi
done

# Generate docs for environments
for env in terraform/environments/*; do
    if [ -d "$env" ]; then
        echo "Generating docs for environment: $(basename $env)"
        terraform-docs -c .terraform-docs.yml "$env"
    fi
done

echo "Documentation generation complete!"