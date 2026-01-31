#!/bin/bash

LOGS_FOLDER="/var/log/shell-roboshop"
LOGS_FILE="$LOGS_FOLDER/$0.log"

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

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

dnf install mysql-server -y &>> $LOGS_FILE
VALIDATE $? "Installing Mysql...."

systemctl enable mysqld &>> $LOGS_FILE
VALIDATE $?  "Enable mysqld"

systemctl start mysqld &>> $LOGS_FILE
VALIDATE $? "Start mysqld"

mysql -uroot -pRoboShop@1 -e "show databases;" &>> $LOGS_FILE
if [ $? -ne 0 ]; then
  mysql_secure_installation --set-root-pass RoboShop@1 &>> $LOGS_FILE
  VALIDATE $? "set root password"
fi