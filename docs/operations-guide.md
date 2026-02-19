# DIGIT HCM Operations Guide

## Table of Contents
1. [Daily Operations](#daily-operations)
2. [Weekly Operations](#weekly-operations)
3. [Monthly Operations](#monthly-operations)
4. [Active Period Procedures](#active-period-procedures)
5. [Idle Period Procedures](#idle-period-procedures)
6. [Emergency Procedures](#emergency-procedures)
7. [Backup and Restore](#backup-and-restore)
8. [Monitoring and Alerting](#monitoring-and-alerting)
9. [Cost Management](#cost-management)

## Daily Operations

### Morning Checklist (9:00 AM)

```bash
# 1. Check cluster health
kubectl get nodes
kubectl get pods --all-namespaces

# 2. Check CloudWatch alarms
aws cloudwatch describe-alarms --state-value ALARM --region af-south-1

# 3. Verify database connections
kubectl exec -n digit-hcm deployment/pgbouncer -- psql -U postgres -d pgbouncer -c "SHOW POOLS;"

# 4. Check Kafka consumer lag
kubectl exec -n digit-hcm deployment/kafka-client -- kafka-consumer-groups --bootstrap-server localhost:9092 --all-groups --describe

# 5. Review previous day's cost
aws ce get-cost-and-usage \
  --time-period Start=$(date -d 'yesterday' +%Y-%m-%d),End=$(date +%Y-%m-%d) \
  --granularity DAILY \
  --metrics "UnblendedCost"