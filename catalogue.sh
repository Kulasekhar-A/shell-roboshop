#!/bin/bash

LOGS_FOLDER="/var/log/shell-roboshop"
LOGS_FILE="$LOGS_FOLDER/$0.log"

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

SCRIPT_DIR="$PWD"
MONGODB_HOST="mongodb.annuru.online"

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

dnf module disable nodejs -y &>> $LOGS_FILE
VALIDATE $? "Disabling Nodejs default version"

dnf module enable nodejs:20 -y &>> $LOGS_FILE
VALIDATE $? "Enable version"

dnf install nodejs -y &>> $LOGS_FILE
VALIDATE $? "Install Nodejs"

id roboshop &>> $LOGS_FILE
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>> $LOGS_FILE
    VALIDATE $> "Creating system user"
else
   echo -e "Already exist ... $Y Skipping it $N"

fi

mkdir -p /app &>> $LOGS_FILE
VALIDATE $? "App directory"

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>> $LOGS_FILE
VALIDATE $? "Download the code"

cd /app &>> $LOGS_FILE
VALIDATE $? "Moving to app directory"

rm -rf /app/*
VALIDATE $? "Removing existing code"

unzip /tmp/catalogue.zip &>> $LOGS_FILE
VALIDATE $? "Unzip the code"

npm install &>> $LOGS_FILE
VALIDATE $? "Installing NPM"

cp $SCRIPT_DIR/catalogue.service /etc/systemd/system/catalogue.service
VALIDATE $? "Copying catalogue service"

systemctl daemon-reload &>> $LOGS_FILE
VALIDATE $? "Reload the service"

systemctl enable catalogue &>> $LOGS_FILE
VALIDATE $? "Enable the catalogue service"

systemctl start catalogue &>> $LOGS_FILE
VALIDATE $? "Start the catalogue service"

cp $SCRIPT_DIR/mongo.repo /etc/yum.repos.d/mongo.repo
VALIDATE $? "copying mongodb repo"

dnf install mongodb-mongosh -y &>> $LOGS_FILE
VALIDATE $? "Install mongodb"

INDEX=$(mongosh --host $MONGODB_HOST --quiet --eval 'db.getMongo().getDBNames().indexOf("catalogue")' )
if [ $INDEX -le 0 ]; then
   mongosh --host $MONGODB_HOST </app/db/master-data.js
   VALIDATE $? "Loading products"
else
   echo -e "Products already loaded ... $Y skipping $N"
fi

systemctl restart cataloge &>> $LOGS_FILE
VALIDATE $? "Restart the catalogue"