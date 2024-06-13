#!/bin/bash

ID=$(id -u)
DATE=$(date +%F:%H:%M:%S)
LOGFILE=/tmp/$(basename $0)-$DATE.log

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

VALIDATE() {
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
    echo -e "${R}Root permissions required,${N}run script with root user."
    exit 1
else
    echo -e "${G}Script executed with root user.${N}"
fi

dnf module disable nodejs -y &>> $LOGFILE
VALIDATE $? "Disabled current nodejs"

dnf module enable nodejs:18 -y &>> $LOGFILE
VALIDATE $? "Enabled nodejs module version 18"

dnf install nodejs -y &>> $LOGFILE
VALIDATE $? "Installed nodejs"

if id "roboshop" &>/dev/null
then
    echo -e "${Y}roboshop user already exists.${N}"
else
    useradd roboshop &>> $LOGFILE
    VALIDATE $? "Created roboshop user"
fi

mkdir -p /app
VALIDATE $? "Created app directory"

# chown roboshop:roboshop /app
# VALIDATE $? "Set permissions for app directory"

cd /app/

curl -o /tmp/cart.zip https://roboshop-builds.s3.amazonaws.com/cart.zip &>> $LOGFILE
VALIDATE $? "Downloaded cart.zip"

unzip /tmp/cart.zip &>> $LOGFILE
VALIDATE $? "Unzipped cart.zip to app directory"

npm install &>> $LOGFILE
VALIDATE $? "Downloaded dependencies"

if [ -f /home/centos/roboshop-shell/cart.service ]
then
    cp /home/centos/roboshop-shell/cart.service /etc/systemd/system/cart.service &>> $LOGFILE
    VALIDATE $? "Copied the service file"
else
    echo -e "${R}Service file not found.${N}"
    exit 1
fi

systemctl daemon-reload &>> $LOGFILE
VALIDATE $? "Reloaded systemd daemon"

systemctl enable cart &>> $LOGFILE
VALIDATE $? "Enabled cart service"

systemctl start cart &>> $LOGFILE
VALIDATE $? "Started cart service"