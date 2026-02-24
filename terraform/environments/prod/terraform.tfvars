# terraform/environments/prod/terraform.tfvars
# DIGIT HCM Production Environment Variables

# AWS Configuration
aws_region        = "af-south-1"
environment       = "prod"

# Cost Optimization Features
use_spot_instances = true

# Seasonal Scaling (DO NOT EDIT MANUALLY - Updated by GitHub Actions)
# May-October: "active"
# November-April: "idle"
current_period    = "idle"

# Database Configuration
database_name     = "digithcm_prod"
database_username = "digithcm_admin"
# Password will be auto-generated and stored in Secrets Manager

# Networking
vpc_cidr          = "10.2.0.0/16"
availability_zones = ["af-south-1a", "af-south-1b"]
