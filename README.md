AWS DIGIT HCM Infrastructure - Complete Guide


aws sts get-caller-identity


📋 Table of Contents
Project Overview

Architecture
Cost-Optimized Design
Prerequisites
Initial Setup
Environment Configuration
Cost-Saving Implementation Guide
Monthly Operations Schedule
Daily/Weekly Tasks
Monitoring & Alerts
Troubleshooting
Budget Tracking
Deployment Guide
GitHub Actions Workflows
Seasonal Auto-Scaling
Emergency Procedures
FAQ
Appendices

1. Project Overview
Business Context
This infrastructure supports DIGIT HCM with a specific budget of $23,000 for 7 months (April - October 2024).

Usage Pattern
Timeline:
├── April - May (2 months): UAT Period
│   └── < 200 users (light testing)
│
├── June - October (5 months): Production Campaign Season
│   ├── 7,000 users actively using the system
│   └── Auto-scales based on month (May-Oct = Active, Nov-Apr = Idle)
│
└── November - March: Idle Season (scaled down)
2. Architecture
High-Level Design
                                    ┌─────────────────┐
                                    │   Internet      │
                                    └────────┬────────┘
                                             │
                                    ┌────────▼────────┐
                                    │  Application    │
                                    │  Load Balancer  │
                                    └────────┬────────┘
                                             │
                                    ┌────────▼────────┐
                                    │   EKS Cluster   │
                                    │   (Kubernetes)  │
                                    └────────┬────────┘
                                             │
              ┌───────────────────┬──────────┼──────────┬───────────────────┐
              │                   │          │          │                   │
     ┌────────▼────────┐ ┌────────▼────────┐│┌────────▼────────┐ ┌────────▼────────┐
     │  Backend Pods   │ │  Frontend Pods  │││   Worker Pods   │ │   PgBouncer     │
     │  (API/Services) │ │    (UI/Assets)  │││  (Queue/Jobs)   │ │  Connection Pool│
     └────────┬────────┘ └────────┬────────┘│└────────┬────────┘ └────────┬────────┘
              │                   │          │         │                   │
     ┌────────▼───────────────────▼──────────┴─────────▼───────────────────▼────────┐
     │                                                                               │
     │                          Private Subnets                                      │
     │                                                                               │
     └────────┬───────────────────┬──────────────────────────┬──────────────────────┘
              │                   │                          │
     ┌────────▼────────┐ ┌────────▼────────┐        ┌────────▼────────┐
     │  Amazon RDS     │ │  ElastiCache    │        │    Amazon MSK   │
     │  PostgreSQL     │ │    Redis        │        │     Kafka       │
     │  (Conditional   │ │  (Auto-scales   │        │  (Dynamic       │
     │   Replica)      │ │   by period)    │        │   Retention)    │
     └─────────────────┘ └─────────────────┘        └─────────────────┘
     
     ┌─────────────────────────────────────────────────────────────────┐
     │                    Cost Optimization Layer                      │
     │  ┌────────────┐  ┌────────────┐  ┌────────────┐  ┌────────────┐ │
     │  │   Spot     │  │ Seasonal   │  │  Lifecycle │  │  Auto-     │ │
     │  │ Instances  │  │  Scaling   │  │  Policies  │  │  Cleanup   │ │
     │  └────────────┘  └────────────┘  └────────────┘  └────────────┘ │
     └─────────────────────────────────────────────────────────────────┘
4. Prerequisites
   Required Tools
# For Windows (using Git Bash or WSL)

# Install AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Install Terraform
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform

# Install kubectl
curl -LO "https://dl.k8s.io/release/v1.27.0/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/

# Install Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Install jq and bc
sudo apt-get install -y jq bc postgresql-client

# For Windows (PowerShell) - Alternative
# Download executables manually and add to PATH
AWS Account Setup
# Configure AWS credentials
aws configure
# AWS Access Key ID: [YOUR_ACCESS_KEY]
# AWS Secret Access Key: [YOUR_SECRET_KEY]
# Default region: af-south-1
# Default output format: json

# Verify setup
aws sts get-caller-identity

GitHub Repository Setup
# Clone the repository
git clone https://github.com/YOUR_USERNAME/aws-digit-infrastructure.git
cd aws-digit-infrastructure

# Configure Git (first time only)
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"

5. Initial Setup

tep 1: Configure GitHub Secrets
Go to your GitHub repository → Settings → Secrets and variables → Actions → Add:

Secret Name	Value	Purpose
AWS_ACCESS_KEY_ID	AKIAXXXXXXXXXXXXXXXX	AWS access key
AWS_SECRET_ACCESS_KEY	xxxxxxxxxxxxxxxxxxxx	AWS secret key
SLACK_WEBHOOK_URL	https://hooks.slack.com/...	Optional - for notifications
Step 2: Verify GitHub Actions
Go to your repository on GitHub

Click on Actions tab

You should see three workflows:

Infrastructure Deployment

Cost Optimization

Emergency Response

If prompted, click "I understand my workflows, go ahead and enable them"

Step 3: Initial Terraform Setup (Local)
bash

# Navigate to environment
cd terraform/environments/prod

# Initialize Terraform
terraform init

# (Optional) See what will be created
terraform plan

# Return to root
cd ../../..

6. Environment Configuration
Production Variables
File: terraform/environments/prod/terraform.tfvars

hcl
aws_region        = "af-south-1"
environment       = "prod"
use_spot_instances = true
current_period    = "idle"  # Auto-updated by GitHub Actions!

Kubernetes ConfigMap
File: kubernetes/digit/configmap.yaml

yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: digit-hcm-config
  namespace: digit-hcm
data:
  APP_ENV: "prod"
  DB_HOST: "pgbouncer"  # Uses connection pooling
  # ... other config
7. Cost-Saving Implementation Guide
How Seasonal Auto-Scaling Works
GitHub Actions runs DAILY at 8 AM:
  ├── Checks current month
  ├── If month between May-October (5-10):
  │     ├── Ensures ACTIVE configuration
  │     ├── 3-5 EKS nodes
  │     ├── RDS read replica enabled
  │     └── Kafka 7-day retention
  │
  └── If month between November-April (11-4, 1-4):
        ├── Ensures IDLE configuration
        ├── 1 EKS node
        ├── No RDS replica
        └── Kafka 1-day retention

        Key Dates - Automatic
Date	Action	Automatic?
May 1	Scale UP for campaign season	✅ Yes
October 31	Still active	✅ Yes
November 1	Scale DOWN for off-season	✅ Yes
