#!/bin/bash

ID=$(id -u)
DATE=$(date +%F:%H:%M:%S)

LOGFILE=/tmp/$(basename $0)-$DATE.log
MONGODB_HOST=mongodb.mechanoidstore.online

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

VALIDATE(){
    if [ $1 -ne 0 ]
    then
        echo -e "$2 . . ${R}FAILED${N}"
        exit 1
    else
        echo -e "$2 . . ${G}SUCCESS${N}"
    fi
}

if [ $ID -ne 0 ]
then
    echo -e "${R}Root permissions required,${N} run script with root user."
    exit 1
else
    echo -e "${G}Script executed with root user.${N}"
fi

dnf module disable nodejs -y &>> $LOGFILE
VALIDATE $? "Disabling current nodejs version"

dnf module enable nodejs:18 -y &>> $LOGFILE
VALIDATE $? "Enabling nodejs version 18"

dnf install nodejs -y &>> $LOGFILE
VALIDATE $? "Installing nodejs"

if id "roboshop" &> /dev/null
then
    echo -e "${Y}roboshop user already exists.${N}"
else
    useradd roboshop &>> $LOGFILE
    VALIDATE $? "Created roboshop user"
fi

mkdir -p /app #parent directory if already exists ignores creating directory again
VALIDATE $? "Creating app directory"

# chown roboshop:roboshop /app
# VALIDATE $? "Set permissions for app directory"

curl -o /tmp/user.zip https://roboshop-builds.s3.amazonaws.com/user.zip &>> $LOGFILE
VALIDATE $? "Downloading the user.zip"

cd /app 

unzip /tmp/user.zip &>> $LOGFILE
VALIDATE $? "Unzipping user.zip"

npm install &>> $LOGFILE
VALIDATE $? "Downloading and Installing all dependencies"

if [ -f /home/centos/roboshop-shell/user.service ]
then
    cp /home/centos/roboshop-shell/user.service /etc/systemd/system/user.service
    VALIDATE $? "Copying the user service file"
else
    echo -e "${R}Service file not found.${N}"
    exit 1
fi

systemctl daemon-reload &>> $LOGFILE
VALIDATE $? "Reloading daemon-reload"

systemctl enable user &>> $LOGFILE
VALIDATE $? "Enabling user service"

systemctl start user &>> $LOGFILE
VALIDATE $? "Starting user service"

if [ -f /home/centos/roboshop-shell/mongo.repo ]
then
    cp /home/centos/roboshop-shell/mongo.repo /etc/yum.repos.d/mongo.repo
    VALIDATE $? "Copying the Mongo repo file"
else
    echo -e "${R}Mongo Repo file not found.${N}"
    exit 1
fi

dnf install mongodb-org-shell -y &>> $LOGFILE
VALIDATE $? "Installing MongoDB-client"

if [ -f /app/schema/user.js ]
then
    mongo --host $MONGODB_HOST </app/schema/user.js
    VALIDATE $? "Loaded data to MongoDB client"
else
    echo -e "${R}Schema file /app/schema/user.js not found.${N}"
    exit 1
fi