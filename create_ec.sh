#!/bin/bash
set -e

#Variable
KEY_NAME="AutomationLabKey"
INSTANCE_TYPE="t2.micro"
AMI_ID=$(aws ec2 describe-images \
    --owners amazon \
    --filters "Name=name,Values=amzn2-ami-hvm-*-x86_64-gp2" \
    --query "Images | sort_by(@,&CreationDate)[-1].ImageId" \
    --output text)
TAG_KEY="Project"
TAG_VALUE="AutomationLab"

echo "Using AMI ID: $AMI_ID"

# create EC2 Key pair 

KEY_CHECK=$(aws ec2 describe-key-pairs \
    --key-names "$KEY_NAME" \
    --query "KeyPairs[0].KeyName" \
    --output text 2>/dev/null)


if [ "$KEY_CHECK" == "$KEY_NAME" ]; then
    echo "Key pair $KEY_NAME already exists. Skipping creation."
else
    echo "Creating Key Pair: $KEY_NAME"
    aws ec2 create-key-pair \
        --key-name "$KEY_NAME" \
        --query 'KeyMaterial' \
        --output text > "${KEY_NAME}.pem"

    chmod 400 "${KEY_NAME}.pem"
    echo "Key pair saved to ${KEY_NAME}.pem"
fi


#Launch EC2 instance

INSTANCE_ID=$(aws ec2 run-instances \
    --image-id "$AMI_ID" \
    --count 1 \
    --instance-type "$INSTANCE_TYPE" \
    --key-name "$KEY_NAME" \
    --tag-specifications "ResourceType=instance,Tags=[{Key=$TAG_KEY,Value=$TAG_VALUE}]" \
    --query "Instances[0].InstanceId" \
    --output text)

echo "Waiting for instance to get public IP..."

PUBLIC_IP=$(aws ec2 describe-instances \
    --instance-ids $INSTANCE_ID \
    --query "Reservations[0].Instances[0].PublicIpAddress" \
    --output text)

# Display instance details

echo "EC2 instance created successfully!"
echo "Instance ID: $INSTANCE_ID"
echo "Public IP: $PUBLIC_IP"