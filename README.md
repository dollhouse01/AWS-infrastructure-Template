# AWS DIGIT HCM Infrastructure - Complete Guide

## 📋 Table of Contents
1. [Project Overview](#project-overview)
2. [Architecture](#architecture)
3. [Cost-Optimized Design](#cost-optimized-design)
4. [Prerequisites](#prerequisites)
5. [Initial Setup](#initial-setup)
6. [Environment Configuration](#environment-configuration)
7. [Cost-Saving Implementation Guide](#cost-saving-implementation-guide)
8. [Monthly Operations Schedule](#monthly-operations-schedule)
9. [Daily/Weekly Tasks](#dailyweekly-tasks)
10. [Monitoring & Alerts](#monitoring--alerts)
11. [Troubleshooting](#troubleshooting)
12. [Budget Tracking](#budget-tracking)
13. [Appendices](#appendices)

---

## 1. Project Overview

### Business Context
This infrastructure supports DIGIT HCM with a specific budget of **$23,000 for 7 months** (April - October 2024).

### Usage Pattern


### Budget Allocation
| Period | Monthly Budget | Total |
|--------|---------------|-------|
| April-May (UAT) | $1,000/month | $2,000 |
| June-October (Production) | $4,200/month | $21,000 |
| **Total** | | **$23,000** |

---

## 2. Architecture

### High-Level Design

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
 │  │   Spot     │  │ Scheduled  │  │  Lifecycle │  │  Auto-     │ │
 │  │ Instances  │  │  Scaling   │  │  Policies  │  │  Cleanup   │ │
 │  └────────────┘  └────────────┘  └────────────┘  └────────────┘ │
 └─────────────────────────────────────────────────────────────────┘

 
---

## 3. Cost-Optimized Design

### Optimization Strategies Implemented

| Strategy | Savings | Implementation |
|----------|---------|----------------|
| **Spot Instances** | 40-50% on compute | Mixed spot/on-demand node groups |
| **Scheduled Scaling** | 50% during idle | CronJobs for auto scaling |
| **Conditional RDS Replica** | $450/month | Replica only during active weeks |
| **Dynamic Kafka Retention** | $200/month | Reduced retention during idle |
| **S3 Lifecycle Policies** | $100/month | Auto-tiering to Glacier |
| **Snapshot Cleanup** | $50/month | Automated deletion of old snapshots |
| **Connection Pooling** | $100/month | PgBouncer reduces database connections |

### Resource Configuration by Period

#### UAT Period (April-May) - <200 Users
| Component | Configuration | Monthly Cost |
|-----------|--------------|--------------|
| EKS Cluster | 1 node (t3.xlarge) - spot | $120 |
| RDS | db.t3.medium, 20GB | $80 |
| ElastiCache | cache.t3.micro | $15 |
| MSK Kafka | 2 nodes (t3.small) - spot | $180 |
| EC2 Workers | 1 t3.medium - spot | $35 |
| Other Services | Minimal | $200 |
| **Total** | | **~$630** |

#### Production Active Weeks (Week 1-2)
| Component | Configuration | Weekly Cost |
|-----------|--------------|-------------|
| EKS Cluster | 3 nodes (r6i.4xlarge) - mix | $900 |
| RDS | db.m6g.xlarge + replica | $650 |
| ElastiCache | cache.r5.large | $180 |
| MSK Kafka | 3 nodes - full retention | $450 |
| Other Services | Full scale | $700 |
| **Total** | | **~$2,880** |

#### Production Idle Weeks (Week 3-4)
| Component | Configuration | Weekly Cost |
|-----------|--------------|-------------|
| EKS Cluster | 1 node (t3.xlarge) | $60 |
| RDS | db.t3.large (no replica) | $120 |
| ElastiCache | cache.t3.medium | $50 |
| MSK Kafka | 2 nodes - reduced retention | $250 |
| Other Services | Minimal | $200 |
| **Total** | | **~$680** |

---

## 4. Prerequisites

### Required Tools
```bash
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

# Install jq and bc (for scripts)
sudo apt-get install -y jq bc postgresql-client