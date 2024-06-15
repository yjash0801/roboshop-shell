#!/bin/bash

AMI=ami-0b4f379183e5706b9
SG_ID=sg-0e28e727304af5f18
INSTANCES=("mongodb" "mysql" "redis" "rabbitmq" "catalogue" "user" "cart" "shipping" "payment" "dispatch" "web")
#LOG=/home/centos/Instance.log

for i in "${INSTANCES[@]}"
do
    if [ $i == "mongodb" ] || [ $i == "mysql" ]
    then
        INSTANCE_TYPE="t3.micro"
    else
        INSTANCE_TYPE="t2.small"
    fi

IP_ADDRESS=$(aws ec2 run-instances --image-id ami-0b4f379183e5706b9 --instance-type $INSTANCE_TYPE  --security-group-ids sg-0e28e727304af5f18 --tag-specification "ResourceType=instance,Tags=[{Key=Name,Value=$i}]" --query 'Instances[0].PrivateIpAddress' --output text)

echo echo "Instance creating: $i: $IP_ADDRESS"

done