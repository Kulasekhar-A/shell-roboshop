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
       echo -e " $2 ...$R FAILURE  $N" | tee -a $LOGS_FILE
       exit 1
   else
       echo -e " $2 ... $G SUCCESS $N" | tee -a $LOGS_FILE
   fi
}

dnf install golang -y &>> $LOGS_FILE
VALIDATE $? "Installing GoLang"

id roboshop &>> $LOGS_FILE
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>> $LOGS_FILE
    VALIDATE $> "Creating system user"
else
   echo -e "Already exist ... $Y Skipping it $N"

fi

mkdir -p /app &>> $LOGS_FILE
VALIDATE $? "App directory"

curl -L -o /tmp/dispatch.zip https://roboshop-artifacts.s3.amazonaws.com/dispatch-v3.zip &>> $LOGS_FILE
VALIDATE $? "Download the code"

cd /app &>> $LOGS_FILE
VALIDATE $? "Moving to app directory"

rm -rf /app/*
VALIDATE $? "Removing existing code"

unzip /tmp/dispatch.zip &>> $LOGS_FILE
VALIDATE $? "Unzip the code"

go mod init dispatch &>> $LOGS_FILE
VALIDATE $? "Intialize go language"

go get &>> $LOGS_FILE
VALIDATE $? "Get the dependences"

go build &>> $LOGS_FILE
VALIDATE $? "Build it"

cp $SCRIPT_DIR/rabbitmq.service /etc/systemd/system/rabbitmq.service
VALIDATE $? "Copying catalogue service"

systemctl daemon-reload &>> $LOGS_FILE
VALIDATE $? "Reload the service"

systemctl enable dispatch &>> $LOGS_FILE
VALIDATE $? "Enable the dispatch service"

systemctl start dispatch &>> $LOGS_FILE
VALIDATE $? "Start the dispatch service"
