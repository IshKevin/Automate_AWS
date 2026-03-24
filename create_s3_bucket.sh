#!/bin/bash
set -e

# Variables
BUCKET_NAME="devops-bucket-$(date +%s)"
REGION="us-east-1"
FILE_NAME="welcome.txt"
TAG_KEY="Project"
TAG_VALUE="AutomationLab"

echo "Creating bucket: $BUCKET_NAME"

# Create bucket
if [ "$REGION" == "us-east-1" ]; then
    aws s3api create-bucket \
        --bucket "$BUCKET_NAME"
else
    aws s3api create-bucket \
        --bucket "$BUCKET_NAME" \
        --region "$REGION" \
        --create-bucket-configuration LocationConstraint="$REGION"
fi

echo "Bucket created: $BUCKET_NAME"

# Enable versioning
aws s3api put-bucket-versioning \
    --bucket "$BUCKET_NAME" \
    --versioning-configuration Status=Enabled

echo "Versioning enabled"

# Tag bucket
aws s3api put-bucket-tagging \
    --bucket "$BUCKET_NAME" \
    --tagging "TagSet=[{Key=$TAG_KEY,Value=$TAG_VALUE}]"

# Create sample file
echo "Welcome to the DevOps Automation Lab!" > "$FILE_NAME"

# Upload file
aws s3 cp "$FILE_NAME" s3://"$BUCKET_NAME"/

echo "File uploaded: $FILE_NAME"

# Create bucket policy
cat <<EOF > bucket-policy.json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::$BUCKET_NAME/*"
    }
  ]
}
EOF

# Allow public access
aws s3api put-public-access-block \
  --bucket "$BUCKET_NAME" \
  --public-access-block-configuration \
  BlockPublicAcls=false,IgnorePublicAcls=false,BlockPublicPolicy=false,RestrictPublicBuckets=false

# Apply bucket policy
aws s3api put-bucket-policy \
    --bucket "$BUCKET_NAME" \
    --policy file://bucket-policy.json

echo "Bucket policy applied"

# Final output
echo "======================================"
echo "S3 Setup Completed Successfully!"
echo "Bucket Name: $BUCKET_NAME"
echo "File URL: https://$BUCKET_NAME.s3.amazonaws.com/$FILE_NAME"
echo "======================================"