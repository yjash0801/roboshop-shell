#!/bin/bash

AMI=ami-0b4f379183e5706b9
SG=sg-0e28e727304af5f18
INSTANCES=("MongoDB" "MySQL" "Redis" "RabbitMQ" "Web" "Catalogue" "User" "Cart" "Shipping" "Payment" "Dispatch")

for i in ${INSTANCES[@]}
do
    if [ i == "MongoDB" ] || [ i == "MySQL" ]
    then
        INSTANCE_TYPE="t3.micro"
    else
        INSTANCE_TYPE="t2.micro"
    fi

    if [ i == web ]
    then
        IP_ADDRESS=$(aws ec2 run-instances --image-id $AMI --instance-type $INSTANCE_TYPE --security-group-ids $SG --query 'Instances[0].PublicIpAddress' --output text)
    else
        IP_ADDRESS=$(aws ec2 run-instances --image-id $AMI --instance-type $INSTANCE_TYPE --security-group-ids $SG --query 'Instances[0].PrivateIpAddress' --output text)
    fi

    echo "Creating Instance $i: $IP_ADDRESS"
done