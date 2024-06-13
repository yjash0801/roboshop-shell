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

dnf module disable mysql -y &>> $LOGFILE
VALIDATE $? "Disabled current MySQL"

if [ -f /home/centos/roboshop-shell/mysql.repo ]
then
    cp /home/centos/roboshop-shell/mysql.repo /etc/yum.repos.d/mysql.repo &>> $LOGFILE
    VALIDATE $? "Copied MySQL repo file"
else
    echo -e "${R}MySQL repo file not found${N}"
    exit 1
fi

dnf install mysql-community-server -y &>> $LOGFILE
VALIDATE $? "Installation MySQL"

systemctl enable mysqld &>> $LOGFILE
VALIDATE $? "Enabling MySQL service"

systemctl start mysqld &>> $LOGFILE
VALIDATE $? "Starting MySQL service"

mysql_secure_installation --set-root-pass RoboShop@1 &>> $LOGFILE
VALIDATE $? "Setting the username and password in MySQL"