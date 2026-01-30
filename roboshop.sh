#!/bin/bash

SG_ID="sg-008da60b2f8f5f062"
AMI_ID="ami-0220d79f3f480ecf5"

ZONE_ID="Z00271701JDWNDD0HCY5L"
DOMAIN_NAME="annuru.online"

for INSTANCE in $@
do

INSTANCE_ID=$(aws ec2 run-instances \
    --image-id $AMI_ID \
    --instance-type t3.micro \
    --security-group-ids $SG_ID \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$INSTANCE}]" \
    --query 'Instances[0].InstanceId' \
    --output text
    )

if [ $INSTANCE == "frontend" ]; then
   IP=$(aws ec2 escribe-instances \
    --instance-ids $INSTANCE_ID \
    --query 'Reservations[].Instances[].PublicIpAddress' \
    --output text
   )
   RECORD_NAME="$DOMAIN_NAME"

else
   IP=$(aws ec2 describe-instances \
    --instance-ids $INSTANCE_ID \
    --query 'Reservations[].Instances[].PrivateIpAddress' \
    --output text
   )
   RECORD_NAME="$INSTANCE.$DOMAIN_NAME"

fi

echo "IP Address : $IP"

aws route53 change-resource-record-sets \
--hosted-zone-id $ZONE_ID \
 --change-batch '
    {
        "Comment": "Update records",
        "Changes": [
            {
            "Action": "UPSERT",
            "ResourceRecordSet": {
                "Name": "'$RECORD_NAME'",
                "Type": "A",
                "TTL": 1,
                "ResourceRecords": [
                {
                    "Value": "'$IP'"
                }
                ]
            }
            }
        ]
    }



'

done

echo "record updated for $INSTANCE"