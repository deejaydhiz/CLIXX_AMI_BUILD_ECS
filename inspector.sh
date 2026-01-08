#!/bin/bash

AMI_ID=$1
SUBNET_ID=$2
IAM_PROFILE="ec2_instance_role" 
REGION="us-east-1"

REPORT_BUCKET="deji-inspector-reports"
KMS_KEY_ARN="arn:aws:kms:us-east-1:055081916963:key/cce0e2fa-b8a8-49ab-b7a1-3f737cd8438b"


# 1. Launch temporary instance
INSTANCE_ID=$(aws ec2 run-instances \
    --image-id $AMI_ID \
    --instance-type t3.micro \
    --subnet-id $SUBNET_ID \
    --iam-instance-profile Name=$IAM_PROFILE \
    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=InspectorScanTemp}]' \
    --query 'Instances[0].InstanceId' --output text)

echo "Launched instance $INSTANCE_ID for scanning..."

# Ensure cleanup on script exit
trap "aws ec2 terminate-instances --instance-ids $INSTANCE_ID > /dev/null; echo 'Instance terminated.'" EXIT

# 2. Wait for Inspector v2 to detect and scan
echo "Waiting for Inspector v2 scan results (this may take a few minutes)..."
# In 2026, we use the wait command for inspector2 findings
aws inspector2 wait for-findings --resource-ids $INSTANCE_ID --region $REGION


# 3. Export findings report to S3
REPORT_ID=$(aws inspector2 create-findings-report \
    --report-format JSON \
    --s3-destination bucketName=$REPORT_BUCKET,keyPrefix=reports/ \
    --kms-key-arn $KMS_KEY_ARN \
    --filter-criteria "{\"resourceId\": [{\"comparison\": \"EQUALS\", \"value\": \"$INSTANCE_ID\"}]}" \
    --query 'reportId' --output text)

echo "Report generation started. ID: $REPORT_ID"

# Wait for the report to be ready (it is generated asynchronously)
while true; do
    STATUS=$(aws inspector2 get-findings-report-status --report-id $REPORT_ID --query 'status' --output text)
    if [ "$STATUS" == "SUCCEEDED" ]; then
        echo "Report successfully exported to S3."
        break
    elif [ "$STATUS" == "FAILED" ]; then
        echo "Report generation failed."
        exit 1
    fi
    echo "Waiting for report... ($STATUS)"
    sleep 10
done