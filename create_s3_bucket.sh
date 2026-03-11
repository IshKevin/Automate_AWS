#!/bin/bash
set -x

#Variables
BUCKET_NAME="devops-bucket-$(date +%s)"
REGION="us-east-1"
FILE_NAME="welcome.txt"

echo "Creating bucket: $BUCKET_NAME"

aws s3api create-bucket \
    --bucket "$BUCKET_NAME" \
    --region "$REGION"

echo "Bucket created: $BUCKET_NAME"

#Enable verioning
aws s3api put-bucket-versioning \
    --bucket "$BUCKET_NAME"
    --versioning-configuration Status=Enabled

echo "Welcome to the DevOps Automation Lab!" > $FILE_NAME

aws s3 cp $FILE_NAME s3://$BUCKET_NAME/

echo "File uploaded: $FILE_NAME"

#Policy
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

# Apply bucket policy
# aws s3api put-bucket-policy \
#     --bucket "$BUCKET_NAME" \
#     --policy file://bucket-policy.json

aws s3api put-public-access-block \
  --bucket "$BUCKET_NAME" \
  --public-access-block-configuration \
  BlockPublicAcls=false,IgnorePublicAcls=false,BlockPublicPolicy=false,RestrictPublicBuckets=false

echo "Bucket policy applied"

echo "Setup completed successfully!"
echo "Bucket Name: $BUCKET_NAME"