#!/bin/bash

AMI=ami-0b4f379183e5706b9
SG=sg-0e28e727304af5f18
INSTANCES=("MongoDB" "MySQL" "Redis" "RabbitMQ" "Web" "Catalogue" "User" "Cart" "Shipping" "Payment" "Dispatch")
ZONEID=Z035925639NOHIW62OJ2G
DOMAIN_NAME="mechanoidstore.online"
GET_IP(){
    instance_id=$1
    ip_type=$2
    if [ $ip_type = "public" ]
    then
        aws ec2 describe-instances --instance-ids $instance_id --query 'Reservations[0].Instances[0].PublicIpAddress' --output text
    else
        aws ec2 describe-instances --instance-ids $instance_id --query 'Reservations[0].Instances[0].PrivateIpAddress' --output text
    fi
}

for i in ${INSTANCES[@]}
do

    if [ $i == "MongoDB" ] || [ $i == "MySQL" ]
    then
        INSTANCE_TYPE="t3.micro"
    else
        INSTANCE_TYPE="t2.micro"
    fi

    INSTANCE_ID=$(aws ec2 run-instances --image-id $AMI --instance-type $INSTANCE_TYPE --security-group-ids $SG --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$i}]" --query 'Instances[0].InstanceId' --output text)

    aws ec2 wait instance-running --instance-ids "$INSTANCE_ID"

    if [ $i == "Web" ]
    then
        IP_ADDRESS=$(GET_IP "$INSTANCE_ID" "public")
    else
        IP_ADDRESS=$(GET_IP "$INSTANCE_ID" "private")
    fi

    aws route53 change-resource-record-sets \
    --hosted-zone-id $ZONEID \
    --change-batch '
    {
        "Comment": "Creating a record set for cognito endpoint",
        "Changes": [{
        "Action"              : "CREATE",
        "ResourceRecordSet"  : {
            "Name"              : "'$i'.'$DOMAIN_NAME'",
            "Type"             : "A",
            "TTL"              : 1,
            "ResourceRecords"  : [{
                "Value"         : "'$IP_ADDRESS'"
            }]
        }
        }]
    }
    '
    echo "Creating Instance $i: $IP_ADDRESS assigned to Rout53 record: $i.$DOMAIN_NAME"
done