#!/bin/bash

SG_ID="sg-008da60b2f8f5f062"
AMI_ID="ami-0220d79f3f480ecf5"

for INSTANCE $@
do

INSTANCE_ID=$(aws ec2 run-instances \
    --image-id $AMI_ID \
    --instance-type t3.micro \
    --security-group-ids $SG_ID \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$INSTANCE}]" \
    --query 'Instances[0].InstanceId' \
    --output text)

if [ $instance == "frontend" ]; then
   IP = $(aws ec2 describe-instances \
    --instance-ids i-$INSTANCE_ID \
    --query 'Reservations[].Instances[].PublicIpAddress' \
    --output text
   )
else
   IP = $(aws ec2 describe-instances \
    --instance-ids i-$INSTANCE_ID \
    --query 'Reservations[].Instances[].PrivateIpAddress' \
    --output text
   )

fi

done