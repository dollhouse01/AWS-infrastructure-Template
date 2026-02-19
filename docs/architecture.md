# DIGIT HCM Architecture Documentation

## System Overview

DIGIT HCM is a cloud-native Human Capital Management platform deployed on AWS. The architecture is designed for high availability, scalability, and cost optimization.

## High-Level Architecture
┌─────────────────────────────────────────────────────────────┐
│ Internet │
└───────────────────────┬─────────────────────────────────────┘
│
┌───────────────────────▼─────────────────────────────────────┐
│ Application Load Balancer │
│ (HTTPS/HTTP, SSL Termination) │
└───────────────────────┬─────────────────────────────────────┘
│
┌───────────────────────▼─────────────────────────────────────┐
│ EKS Cluster │
│ ┌─────────────────────────────────────────────────────┐ │
│ │ ┌──────────┐ ┌──────────┐ ┌──────────┐ │ │
│ │ │ Backend │ │ Frontend │ │ Worker │ │ │
│ │ │ Pods │ │ Pods │ │ Pods │ │ │
│ │ └──────────┘ └──────────┘ └──────────┘ │ │
│ │ ┌──────────┐ ┌──────────┐ ┌──────────┐ │ │
│ │ │PgBouncer │ │ Kafka │ │ Redis │ │ │
│ │ │ Pods │ │ Pods │ │ Pods │ │ │
│ │ └──────────┘ └──────────┘ └──────────┘ │ │
│ └─────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
│
┌───────────────┼───────────────┐
│ │ │
┌───────▼───────┐ ┌─────▼──────┐ ┌──────▼───────┐
│ Amazon RDS │ │ElastiCache │ │ Amazon MSK │
│ PostgreSQL │ │ Redis │ │ Kafka │
│ (Primary + │ │ (Cache) │ │ (3 brokers) │
│ Replica) │ └────────────┘ └──────────────┘
└───────────────┘


## Component Details

### 1. Compute Layer (EKS)
- **Cluster**: Amazon EKS (Kubernetes 1.27)
- **Node Groups**: Mixed spot and on-demand instances
- **Auto-scaling**: Horizontal Pod Autoscaler based on CPU/memory
- **Cost Optimization**: 40% savings using spot instances

### 2. Database Layer (RDS)
- **Engine**: PostgreSQL 15
- **Instance**: db.m6g.xlarge (active), db.t3.large (idle)
- **Replica**: Conditional read replica during active weeks
- **Backup**: Automated daily, 30-day retention
- **Connection Pooling**: PgBouncer for 1000+ connections

### 3. Caching Layer (ElastiCache)
- **Engine**: Redis 7.0
- **Instance**: cache.r5.large (active), cache.t3.medium (idle)
- **Purpose**: Session storage, API response caching
- **Hit Rate**: >90% cache hit ratio

### 4. Message Queue (MSK)
- **Engine**: Apache Kafka 3.4
- **Brokers**: 3 nodes (active), 2 nodes (idle)
- **Storage**: 200GB per broker
- **Retention**: 7 days (active), 1 day (idle)

### 5. Networking
- **VPC**: 10.0.0.0/16 with public/private subnets
- **Load Balancer**: Application Load Balancer
- **NAT Gateway**: Single for outbound internet
- **Security Groups**: Least-privilege access

## Data Flow

### User Request Flow

User → ALB → Ingress → Backend Service → Backend Pod

Backend Pod → PgBouncer → RDS (for data)

Backend Pod → Redis (for cache)

Backend Pod → Kafka (for async tasks)

Worker Pods consume Kafka messages