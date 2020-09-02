#!/bin/bash

echo "deb http://ftp.fr.debian.org/debian testing main" >> /etc/apt/sources.list
apt update -y
apt install python3-distutils python3.8 -y
pip3 -V
