#!/bin/bash

ID=$(id -u)
DATE=$(date +%F:%H:%M:%S)

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOGFILE=/tmp/$(basename-$0)-$DATE.log

VALIDATE() {
    if [ $1 -ne 0 ]
    then
        echo -e "$N $2 . . ${R}FAILED${N}"
    else
        echo -e "$N $2 . . ${G}SUCCESS${N}"
    fi
}

if [ $ID -ne 0 ]
then
    echo -e "${R}Root permissions required,${N}run script with root user."
    exit 1
else
    echo -e "${G}Script executed with root user.${N}"

dnf install https://rpms.remirepo.net/enterprise/remi-release-8.rpm -y &>> $LOGFILE
VALIDATE $? "Installing Redis rpm repo file"

dnf module enable redis:remi-6.2 -y &>> $LOGFILE
VALIDATE $? "Enabling Redis 6.2 from package streams."

dnf install redis -y &>> $LOGFILE
VALIDATE $? "Installing Redis"

sed -i "s/127.0.0.1/0.0.0.0/g" /etc/redis.conf &>> $LOGFILE
VALIDATE $? "Remote Access to Redis"

systemctl enable redis
VALIDATE $? "Enabling Redis service"

systemctl start redis
VALIDATE $? "Starting Redis service"