#!/bin/bash

#For_Dataideas_Debian_10_ssh
password=$1
apt install ssh screen zip unzip lrzsz -y
echo root:${password} |sudo chpasswd root
sed -i 's/^.*PermitRootLogin.*/PermitRootLogin yes/g' /etc/ssh/sshd_config;
sed -i 's/^.*PasswordAuthentication.*/PasswordAuthentication yes/g' /etc/ssh/sshd_config;
service sshd restart
