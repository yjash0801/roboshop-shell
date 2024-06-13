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

dnf install maven -y &>> $LOGFILE
VALIDATE $? "Installing Maven"

if id "roboshop" &>/dev/null
then
    echo -e "${Y}roboshop user already exist.${N}"
else
    useradd roboshop &>> $LOGFILE
    VALIDATE $? "Creating roboshop user"
fi

mkdir -p /app
VALIDATE $? "Creating app directory"

curl -o /tmp/shipping.zip https://roboshop-builds.s3.amazonaws.com/shipping.zip &>> $LOGFILE
VALIDATE $? "Downloading the shipping.zip"

cd /app

unzip /tmp/shipping.zip &>> $LOGFILE
VALIDATE $? "Unzipped shipping.zip to app directory"

mvn clean package &>> $LOGFILE
VALIDATE $? "Downloading and Installing all dependencies"

if [ -f /home/centos/roboshop-shell/shipping.service ]
then
    cp /home/centos/roboshop-shell/shipping.service /etc/systemd/system/shipping.service &>> $LOGFILE
    VALIDATE $? "Copied the service file"
else
    echo -e "${R}Service file not found"
    exit 1
fi

systemctl daemon-reload &>> $LOGFILE
VALIDATE $? "Reloading daemon-reload"

systemctl enable shipping &>> $LOGFILE
VALIDATE $? "Enabling shipping service"

systemctl start shipping &>> $LOGFILE
VALIDATE $? "Starting shipping service"

dnf install mysql -y &>> $LOGFILE
VALIDATE $? "Installing MySQL"

if [ -f /app/schema/shipping.sql ]
then
    mysql -h mysql.mechanoidstore.online -uroot -pRoboShop@1 < /app/schema/shipping.sql &>> $LOGFILE
    VALIDATE $? "Loaded data to MySQL"
else
    echo -e "${R}Schema file /app/schema/shipping.sql not found.${N}"
    exit 1
fi