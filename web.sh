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
        echo -e "$2 . . $R failed $N"
        exit 1
    else
        echo -e "$2 . . $R success $N"
}

if [ $ID -ne 0 ]
then
    echo "$R root permission required,$N run script with super user"
    exit 1
else
    echo "$G Script executed with root user. $N"
fi

dnf install nginx -y &>> $LOGFILE
VALIDATE $? "INSTALLED Nginx"

systemctl enable nginx &>> $LOGFILE
VALIDATE "Enabling Nginx Service"

systemctl start nginx &>> $LOGFILE
VALIDATE "Starting Nginx Service"

rm -rf /usr/share/nginx/html/* &>> $LOGFILE
VALIDATE "Removing default content in Nginx"

curl -o /tmp/web.zip https://roboshop-builds.s3.amazonaws.com/web.zip
VALIDATE $? "Downloading web.zip"

cd /usr/share/nginx/html &>> $LOGFILE
VALIDATE $? "Navigated to /usr/share/nginx/html"

unzip -o /tmp/web.zip &>> $LOGFILE
VALIDATE $? "Unzipping web.zip"

if [ -f /home/centos/roboshop-shell/roboshop.conf ]
then
    cp /home/centos/roboshop-shell/roboshop.conf /etc/nginx/default.d/roboshop.conf &>> $LOGFILE
    VALIDATE $? "Copying the roboshop configuration file"
else
    echo -e "$R Service file not found. $N"
    exit 1
fi

systemctl restart nginx &>> $LOGFILE
VALIDATE "Restarting Nginx Service"