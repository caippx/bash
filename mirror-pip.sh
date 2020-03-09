#!/bin/bash

function centos(){
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
" > .pip/pip.conf
}

function ubuntu16(){
mv /etc/apt/sources.list /etc/apt/sources.list.bak
echo "
deb http://mirrors.aliyun.com/ubuntu/ xenial main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu/ xenial-security main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu/ xenial-updates main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu/ xenial-proposed main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu/ xenial-backports main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ xenial main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ xenial-security main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ xenial-updates main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ xenial-proposed main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ xenial-backports main restricted universe multiverse
" > /etc/apt/sources.list
apt update
cd ~ && mkdir .pip
echo "
[global]
index-url=http://mirrors.aliyun.com/pypi/simple/
trusted-host=mirrors.aliyun.com
" > .pip/pip.conf
}

function ubuntu18(){
mv /etc/apt/sources.list /etc/apt/sources.list.bak
echo "
deb http://mirrors.aliyun.com/ubuntu/ bionic main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu/ bionic-security main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu/ bionic-updates main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu/ bionic-proposed main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu/ bionic-backports main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ bionic main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ bionic-security main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ bionic-updates main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ bionic-proposed main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ bionic-backports main restricted universe multiverse
" > /etc/apt/sources.list
apt update
cd ~ && mkdir .pip
echo "
[global]
index-url=http://mirrors.aliyun.com/pypi/simple/
trusted-host=mirrors.aliyun.com
" > .pip/pip.conf
}
