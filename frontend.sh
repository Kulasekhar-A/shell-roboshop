#!/bin/bash

LOGS_FOLDER="/var/log/shell-roboshop"
LOGS_FILE="$LOGS_FOLDER/$0.log"

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

SCRIPT_DIR="$PWD"

USERID=$(id -u)

if [ $USERID -ne 0 ]; then
  echo -e "$R Please run this script with root user access $N" | tee -a $LOGS_FILE
  exit 1
fi

mkdir -p  $LOGS_FOLDER

VALIDATE(){
   if [ $1 -ne 0 ]; then
       echo -e" $2 ...$R FAILURE  $N" | tee -a $LOGS_FILE
       exit 1
   else
       echo -e " $2 ... $G SUCCESS $N" | tee -a $LOGS_FILE
   fi
}

dnf module disable nginx -y &>> $LOGS_FILE
VALIDATE $? "Disabling Nginx default version"

dnf module enable nginx:1.24 -y &>> $LOGS_FILE
VALIDATE $? "Enable Nginx version"

dnf install nginx -y &>> $LOGS_FILE
VALIDATE $? "Installing Nginx ..."

systemctl enable nginx &>> $LOGS_FILE
VALIDATE $? "Enable nginx"

systemctl start nginx &>> $LOGS_FILE
VALIDATE $? "Starting nginx"

curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip &>> $LOGS_FIL
VALIDATE $? "Download the code"

cd /usr/share/nginx/html &>> $LOGS_FILE
VALIDATE $? "Moving the /usr/share/nginx/html directory"

rm -rf /usr/share/nginx/html/* &>> $LOGS_FILE
VALIDATE $? "Remove the default content inside web server"

unzip /tmp/frontend.zip &>> $LOGS_FILE
VALIDATE $? "Unzip the code"

cp $SCRIPT_DIR/nginx.conf /etc/nginx/nginx.conf &>> $LOGS_FILE
VALIDATE $? "copying nginx configure" 

systemctl restart nginx &>> $LOGS_FILE
VALIDATE $? "Restart the Nginx"