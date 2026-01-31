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

dnf install python3 gcc python3-devel -y &>> $LOGS_FILE
VALIDATE $? "Installing python3-devel version"

id roboshop &>> $LOGS_FILE
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>> $LOGS_FILE
    VALIDATE $> "Creating system user"
else
   echo -e "Already exist ... $Y Skipping it $N"

fi

mkdir -p /app &>> $LOGS_FILE
VALIDATE $? "App directory"

curl -L -o /tmp/payment.zip https://roboshop-artifacts.s3.amazonaws.com/payment-v3.zip  &>> $LOGS_FILE
VALIDATE $? "Download the code"

cd /app &>> $LOGS_FILE
VALIDATE $? "Moving to app directory"

rm -rf /app/*
VALIDATE $? "Removing existing code"

unzip /tmp/payment.zip &>> $LOGS_FILE
VALIDATE $? "Unzip the code"


pip3 install -r requirements.txt 
VALIDATE $? "Install the python dependencies"

cp $SCRIPT_DIR/payment.service /etc/systemd/system/payment.service
VALIDATE $? "Copying payment service"

systemctl daemon-reload &>> $LOGS_FILE
VALIDATE $? "Reload the service"

systemctl enable payment &>> $LOGS_FILE
VALIDATE $? "Enable the payment service"

systemctl start payment &>> $LOGS_FILE
VALIDATE $? "Start the payment service"

