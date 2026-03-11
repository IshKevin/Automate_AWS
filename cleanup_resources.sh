#!/bin/bash

TAG_KEY="Project"
TAG_VALUE="AutomationLab"

echo "Starting cleanup..."

# Find EC2 instances with the tag
INSTANCE_IDS=$(aws ec2 describe-instances \
    --filters "Name=tag:$TAG_KEY,Values=$TAG_VALUE" \
    --query "Reservations[].Instances[].InstanceId" \
    --output text)

if [ -n "$INSTANCE_IDS" ]; then
    echo "Terminating EC2 instances: $INSTANCE_IDS"
    aws ec2 terminate-instances --instance-ids $INSTANCE_IDS
else
    echo "No EC2 instances found"
fi

# Delete security group
SG_ID=$(aws ec2 describe-security-groups \
    --filters "Name=group-name,Values=devops-sg" \
    --query "SecurityGroups[0].GroupId" \
    --output text)

if [ "$SG_ID" != "None" ]; then
    echo "Deleting security group: $SG_ID"
    aws ec2 delete-security-group --group-id $SG_ID
else
    echo "No security group found"
fi

# Delete key pair
echo "Deleting key pair"
aws ec2 delete-key-pair --key-name AutomationLabKey

# Find S3 buckets created by script
BUCKETS=$(aws s3api list-buckets \
    --query "Buckets[].Name" \
    --output text | tr '\t' '\n' | grep devops-bucket)

for BUCKET in $BUCKETS
do
    echo "Cleaning bucket: $BUCKET"

    # Remove all objects
    aws s3 rm s3://$BUCKET --recursive

    # Delete bucket
    aws s3api delete-bucket --bucket $BUCKET
done

echo "Cleanup completed."