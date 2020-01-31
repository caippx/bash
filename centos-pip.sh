#!/bin/bash

mv /etc/yum.repos.d /etc/yum.repos.d.backup
mkdir /etc/yum.repos.d
wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo
wget -O /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo
yum clean all
yum makecache
yum install python-pip -y
cd ~ && mkdir .pip
echo "
[global]
index-url=http://mirrors.aliyun.com/pypi/simple/
trusted-host=mirrors.aliyun.com
" > pip.conf
