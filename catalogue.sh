#!/bin/bash

ID=$(id -u)
DATE=$(date +%F:%H:%M:%S)

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOGFILE=/tmp/$(basename $0)-$DATE.log
MONGODB_HOST=mongodb.mechanoidstore.online

VALIDATE() {
    if [ $1 -ne 0 ]
    then
        echo -e "$2 . . $R failed $N"
    else
        echo -e "$2 . . $G success $N"
    fi
}

if [ $ID -ne 0 ]
then
    echo -e "$R Root permissions required,$N run script with root user."
    exit 1
else
    echo -e "$G Script executed with root user. $N"
fi

dnf module disable nodejs -y &>> $LOGFILE
VALIDATE $? "Disabled current nodejs module"

dnf module enable nodejs:18 -y &>> $LOGFILE
VALIDATE $? "Enabled nodejs module version 18"

dnf install nodejs -y &>> $LOGFILE
VALIDATE $? "Installed nodejs"

if id "roboshop" &>/dev/null; then
    echo -e "$Y roboshop user already exists. $N"
else
    useradd roboshop &>> $LOGFILE
    VALIDATE $? "Created roboshop user"
fi

mkdir -p /app
VALIDATE $? "Created app directory"

chown roboshop:roboshop /app
VALIDATE $? "Set permissions for app directory"

cd /app/

curl -o /tmp/catalogue.zip https://roboshop-builds.s3.amazonaws.com/catalogue.zip &>> $LOGFILE
VALIDATE $? "Downloaded catalogue.zip"

unzip -o /tmp/catalogue.zip &>> $LOGFILE
VALIDATE $? "Unzipped catalogue.zip to app directory"

npm install &>> $LOGFILE
VALIDATE $? "Downloaded dependencies"

if [ -f /home/centos/roboshop-shell/catalogue.service ]; then
    cp /home/centos/roboshop-shell/catalogue.service /etc/systemd/system/catalogue.service &>> $LOGFILE
    VALIDATE $? "Copied the service file"
else
    echo -e "$R Service file not found. $N"
    exit 1
fi

systemctl daemon-reload &>> $LOGFILE
VALIDATE $? "Reloaded systemd daemon"

systemctl enable catalogue &>> $LOGFILE
VALIDATE $? "Enabled catalogue service"

systemctl start catalogue &>> $LOGFILE
VALIDATE $? "Started catalogue service"

if [ -f /home/centos/roboshop-shell/mongo.repo ]; then
    cp /home/centos/roboshop-shell/mongo.repo /etc/yum.repos.d/mongo.repo &>> $LOGFILE
    VALIDATE $? "Copied Mongo repo file"
else
    echo -e "$R Mongo repo file not found. $N"
    exit 1
fi

dnf install mongodb-org-shell -y &>> $LOGFILE
VALIDATE $? "Installed MongoDB client"

if [ -f /app/schema/catalogue.js ]; then
    mongo --host $MONGODB_HOST </app/schema/catalogue.js &>> $LOGFILE
    VALIDATE $? "Loaded data to MongoDB client"
else
    echo -e "$R Schema file /app/schema/catalogue.js not found. $N" | tee -a $LOGFILE
    exit 1
fi