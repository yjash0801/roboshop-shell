#!/bin/bash

ID=$(id -u)
DATE=$(date +%F:%H:%M:%S)

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOGFILE=/tmp/$0-$DATE.log
MONGODB_HOST=mongodb.mechanoidstore.online

VALIDATE() {
    if [ $1 -ne 0 ]
    then
        echo -e "$N $2 . . $R failed"
    else
        echo -e "$N $2 . . $G sucess"
    fi
}

if [ $ID -ne 0 ]
then
    echo -e "$R Root permissions required,$N run script with root user."
    exit 1
else
    echo -e "$G Script executed with root user."
fi

dnf module disable nodejs -y &>> $LOGFILE
VALIDATE $? "Disabled current nodejs module"

dnf module enable nodejs:18 -y &>> $LOGFILE
VALIDATE $? "Enabled nodejs module version 18"

dnf install nodejs -y &>> $LOGFILE
VALIDATE $? "INSTALLATION nodejs"

useradd roboshop &>> $LOGFILE
VALIDATE $? "roboshop user created"

mkdir -p /app
VALIDATE $? "app directory created"

cd /app/

curl -o /tmp/catalogue.zip https://roboshop-builds.s3.amazonaws.com/catalogue.zip &>> $LOGFILE
VALIDATE $? "Download catalogue.zip"

unzip /tmp/catalogue.zip &>> $LOGFILE
VALIDATE $? "Unzipping catalogue.zip to app directory"

npm install &>> $LOGFILE
VALIDATE $? "Downloading the dependencies"

cp /home/centos/roboshop-shell/catalogue.service /etc/systemd/system/catalogue.service &>> $LOGFILE
VALIDATE $? "Copied the service file"

systemctl daemon-reload &>> $LOGFILE
VALIDATE $? "daemon-reload"

systemctl enable catalogue &>> $LOGFILE
VALIDATE $? "Enable catalogue service"

systemctl start catalogue &>> $LOGFILE
VALIDATE $? "Start catalogue service"

cp /home/centos/roboshop-shell/mongo.repo /etc/yum.repos.d/mongo.repo &>> $LOGFILE
VALIDATE $? "Copied Mongo repo file"

dnf install mongodb-org-shell -y &>> $LOGFILE
VALIDATE $? "INSTALLATION MongoDB client"

mongo --host $MONGODB_HOST </app/schema/catalogue.js &>> $LOGFILE
VALIDATE $? "Loading the data to MongoDB client"