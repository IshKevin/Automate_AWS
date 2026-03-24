#!/bin/bash
set -e

TAG_KEY="Project"
TAG_VALUE="AutomationLab"
KEY_NAME="AutomationLabKey"

echo "Starting cleanup..."

# =========================
# TERMINATE EC2 INSTANCES
# =========================
INSTANCE_IDS=$(aws ec2 describe-instances \
    --filters "Name=tag:$TAG_KEY,Values=$TAG_VALUE" \
    --query "Reservations[].Instances[].InstanceId" \
    --output text)

if [ -n "$INSTANCE_IDS" ]; then
    echo "Terminating EC2 instances: $INSTANCE_IDS"
    aws ec2 terminate-instances --instance-ids $INSTANCE_IDS

    echo "Waiting for instances to terminate..."
    aws ec2 wait instance-terminated --instance-ids $INSTANCE_IDS
else
    echo "No EC2 instances found"
fi

# =========================
# DELETE SECURITY GROUP
# =========================
SG_ID=$(aws ec2 describe-security-groups \
    --filters "Name=tag:$TAG_KEY,Values=$TAG_VALUE" \
    --query "SecurityGroups[0].GroupId" \
    --output text)

if [ "$SG_ID" != "None" ]; then
    echo "Deleting security group: $SG_ID"
    aws ec2 delete-security-group --group-id "$SG_ID"
else
    echo "No tagged security group found"
fi

# =========================
# DELETE KEY PAIR
# =========================
if aws ec2 describe-key-pairs --key-names "$KEY_NAME" >/dev/null 2>&1; then
    echo "Deleting key pair: $KEY_NAME"
    aws ec2 delete-key-pair --key-name "$KEY_NAME"
else
    echo "Key pair not found"
fi

# =========================
# DELETE S3 BUCKETS
# =========================
BUCKETS=$(aws s3api list-buckets \
    --query "Buckets[].Name" \
    --output text)

for BUCKET in $BUCKETS
do
    TAG_CHECK=$(aws s3api get-bucket-tagging \
        --bucket "$BUCKET" \
        --query "TagSet[?Key=='$TAG_KEY' && Value=='$TAG_VALUE']" \
        --output text 2>/dev/null || true)

    if [ -n "$TAG_CHECK" ]; then
        echo "Deleting tagged bucket: $BUCKET"

        # Delete all versions
        aws s3api delete-objects \
            --bucket "$BUCKET" \
            --delete "$(aws s3api list-object-versions \
                --bucket "$BUCKET" \
                --query='{Objects: Versions[].{Key:Key,VersionId:VersionId}}')"

        # Delete remaining objects
        aws s3 rm s3://"$BUCKET" --recursive || true

        # Delete bucket
        aws s3api delete-bucket --bucket "$BUCKET"
    fi
done

echo "======================================"
echo "Cleanup completed successfully!"
echo "======================================"