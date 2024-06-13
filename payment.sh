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
    echo -e "${R}Root permissions required,${N} run script with root user."
    exit 1
else
    echo -e "${G}Script executed with root user.${N}"
fi

dnf install python36 gcc python3-devel -y &>> $LOGFILE
VALIDATE $? "Installing Python"

if id "roboshop" &>/dev/null
then
    echo -e "${Y}roboshop user already exist.${N}"
else
    useradd roboshop &>> $LOGFILE
    VALIDATE $? "Creating roboshop user"
fi

mkdir -p /app &>> $LOGFILE
VALIDATE $? "creating app directory"

curl -L -o /tmp/payment.zip https://roboshop-builds.s3.amazonaws.com/payment.zip &>> $LOGFILE
VALIDATE $? "Downloading payment.zip"

cd /app 

unzip -o /tmp/payment.zip &>> $LOGFILE
VALIDATE $? "Unzipped payment.zip to app directory"

pip3.6 install -r requirements.txt &>> $LOGFILE
VALIDATE $? "Downloading and Installing all dependencies"

if [ -f /home/centos/roboshop-shell/payment.service ]
then
    cp /home/centos/roboshop-shell/payment.service /etc/systemd/system/payment.service &>> $LOGFILE
    VALIDATE $? "Copying payment service"
else
    echo -e "${R}Service file not found.${N}"
    exit 1
fi

systemctl daemon-reload &>> $LOGFILE
VALIDATE $? "Reloading daemon reaload"

systemctl enable payment  &>> $LOGFILE
VALIDATE $? "Enabling payment service"

systemctl start payment &>> $LOGFILE
VALIDATE $? "Starting payment"