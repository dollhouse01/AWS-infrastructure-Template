#!/bin/bash
# weekly-cost-report.sh - Generate and email weekly cost report

set -e

# Configuration
ENVIRONMENT=${1:-prod}
EMAIL_RECIPIENT=${2:-"admin@example.com"}
SLACK_WEBHOOK=${SLACK_WEBHOOK:-""}

echo "Generating weekly cost report for $ENVIRONMENT..."

# Calculate date range
END_DATE=$(date +%Y-%m-%d)
START_DATE=$(date -d '7 days ago' +%Y-%m-%d)

# Create report file
REPORT_FILE="/tmp/cost-report-$(date +%Y%m%d).txt"

{
    echo "=========================================="
    echo "WEEKLY COST REPORT"
    echo "Environment: $ENVIRONMENT"
    echo "Period: $START_DATE to $END_DATE"
    echo "=========================================="
    echo ""
    
    # Get cost by service
    echo "COST BY SERVICE"
    echo "------------------------------------------"
    aws ce get-cost-and-usage \
        --time-period Start=$START_DATE,End=$END_DATE \
        --granularity MONTHLY \
        --metrics "UnblendedCost" \
        --group-by Type=DIMENSION,Key=SERVICE \
        --query "ResultsByTime[0].Groups[*].[Keys[0], Metrics.UnblendedCost.Amount]" \
        --output text | sort -k2 -rn | while read SERVICE COST; do
        printf "%-40s $%8.2f\n" "$SERVICE" "$COST"
    done
    
    echo ""
    echo "DAILY BREAKDOWN"
    echo "------------------------------------------"
    aws ce get-cost-and-usage \
        --time-period Start=$START_DATE,End=$END_DATE \
        --granularity DAILY \
        --metrics "UnblendedCost" \
        --query "ResultsByTime[*].[TimePeriod.Start, Metrics.UnblendedCost.Amount]" \
        --output text | while read DATE COST; do
        printf "%s $%8.2f\n" "$DATE" "$COST"
    done
    
    echo ""
    echo "TOTAL COST"
    echo "------------------------------------------"
    TOTAL_COST=$(aws ce get-cost-and-usage \
        --time-period Start=$START_DATE,End=$END_DATE \
        --granularity MONTHLY \
        --metrics "UnblendedCost" \
        --query "ResultsByTime[0].Total.UnblendedCost.Amount" \
        --output text)
    printf "Weekly Total: $%8.2f\n" "$TOTAL_COST"
    
    # Compare with previous week
    PREV_START=$(date -d '14 days ago' +%Y-%m-%d)
    PREV_END=$(date -d '7 days ago' +%Y-%m-%d)
    
    PREV_COST=$(aws ce get-cost-and-usage \
        --time-period Start=$PREV_START,End=$PREV_END \
        --granularity MONTHLY \
        --metrics "UnblendedCost" \
        --query "ResultsByTime[0].Total.UnblendedCost.Amount" \
        --output text)
    
    CHANGE=$(echo "scale=2; ($TOTAL_COST - $PREV_COST) / $PREV_COST * 100" | bc)
    echo "Previous Week: \$$PREV_COST"
    echo "Change: ${CHANGE}%"
    
    echo ""
    echo "COST OPTIMIZATION SAVINGS"
    echo "------------------------------------------"
    
    # Estimate spot savings
    SPOT_NODES=$(kubectl get nodes -l capacity-type=spot -o name 2>/dev/null | wc -l)
    if [ $SPOT_NODES -gt 0 ]; then
        SPOT_SAVINGS=$(echo "$SPOT_NODES * 0.7 * 24 * 7" | bc)
        printf "Spot Instances: \$%8.2f\n" "$SPOT_SAVINGS"
    fi
    
    echo ""
    echo "RECOMMENDATIONS"
    echo "------------------------------------------"
    echo "• Run ./scripts/cleanup-old-snapshots.sh to clean up old EBS snapshots"
    echo "• Run ./scripts/manage-database.sh $ENVIRONMENT archive-old-data if not run this month"
    echo "• Check if you're in active/idle period and run scheduled-scaling.sh accordingly"
    
} > $REPORT_FILE

# Display report
cat $REPORT_FILE

# Send email if configured
if [ -n "$EMAIL_RECIPIENT" ] && command -v aws ses &> /dev/null; then
    echo "Sending email report to $EMAIL_RECIPIENT..."
    aws ses send-email \
        --from "cost-reports@${ENVIRONMENT}.digit-hcm.com" \
        --destination "ToAddresses=$EMAIL_RECIPIENT" \
        --message "Subject={Data=Weekly Cost Report - $ENVIRONMENT,Charset=utf8},Body={Text={Data=$(cat $REPORT_FILE),Charset=utf8}}" \
        --region $AWS_REGION || true
fi

# Send to Slack if configured
if [ -n "$SLACK_WEBHOOK" ]; then
    echo "Sending to Slack..."
    TOTAL_COST=$(aws ce get-cost-and-usage \
        --time-period Start=$START_DATE,End=$END_DATE \
        --granularity MONTHLY \
        --metrics "UnblendedCost" \
        --query "ResultsByTime[0].Total.UnblendedCost.Amount" \
        --output text)
    
    curl -X POST -H 'Content-type: application/json' \
        --data "{\"text\":\"Weekly Cost Report for $ENVIRONMENT\nPeriod: $START_DATE to $END_DATE\nTotal: \$$TOTAL_COST\"}" \
        $SLACK_WEBHOOK || true
fi

echo "Report saved to: $REPORT_FILE"