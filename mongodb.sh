#!/bin/bash

ID=$(id -u)
DATE=$(date +%F:%H:%M:%S)

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOGFILE=/tmp/$(basename $0)-$DATE.log

VALIDATE() {
    if [ $1 -ne 0 ]
    then
        echo -e "${N}$2 . . ${R}FAILED${N}"
    else
        echo -e "${N}$2 . . ${G}SUCCESS${N}"
    fi
}

if [ $ID -ne 0 ]
then
    echo -e "${R}Root permissions required,${N} run script with root user."
    exit 1
else
    echo -e "${G}Script executed with root user."
fi

if [ -f /home/centos/roboshop-shell/mongo.repo ]
then
    cp /home/centos/roboshop-shell/mongo.repo /etc/yum.repos.d/mongo.repo &>> $LOGFILE
    VALIDATE $? "Copied Mongo repo file"
else
    echo -e "${R}Mongo Repo file not found${N}"
    exit 1
fi

dnf install mongodb-org -y &>> $LOGFILE
VALIDATE $? "MONGODB INSTALLATION"

systemctl enable mongod &>> $LOGFILE
VALIDATE $? "Enabled MONGODB service"

systemctl start mongod &>> $LOGFILE
VALIDATE $? "Started MONGODB service"

sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf &>> $LOGFILE
VALIDATE $? "Remote access to MongoDB"

systemctl restart mongod &>> $LOGFILE
VALIDATE $? "restarted MONGODB service"