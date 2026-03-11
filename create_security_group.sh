#!/bin/bash

#Variable 
SG_NAME="developer-sg"
DESCRIPTION="Securty group for DevOps automation lab"

#Get VPC ID
VPC_ID=$(aws ec2 describe-vpcs \
    --filter "Name=isDefault,Values=true" \
    --query "Vpcs[0].VpcId" \
    --output text)

echo "Using VPC: $VPC_ID"

#Create securty group 
SG_ID=$(aws ec2 create-security-group \
    --group-name "$SG_NAME" \
    --description "$DESCRIPTION" \
    --vpc-id "$VPC_ID" \
    --query "GroupId" \
    --output text)

echo "Securty Group Created: $SG_ID"

# Allow SSH (port 22)
aws ec2 authorize-security-group-ingress \
    --group-id "$SG_ID" \
    --protocol tcp \
    --port 22 \
    --cidr 0.0.0.0/0

#Allow HTTP (port 80)
aws ec2 authorize-security-group-ingress \
    --group-id "$SG_ID" \
    --protocol tcp \
    --port 80 \
    --cidr 0.0.0.0/0

# Display security group details
echo "Security Group Rules:"
aws ec2 describe-security-groups \
    --group-ids "$SG_ID" \
    --query "SecurityGroups[0].IpPermissions"