#!/bin/bash

function install_rinetd(){
echo "自动安装可能只适应debian10"
apt install rinetd
echo "allow *.*.*.*" >> /etc/rinetd.conf
}

function list(){
ps -ef | grep -v grep | grep "rinetd"
}

function run(){
echo && stty erase '^H' && read -p "输入远程IP（域名）: " proxy_ip
echo && stty erase '^H' && read -p "输入远程端口: " proxy_port
echo && stty erase '^H' && read -p "输入本地端口: " local_port
echo "0.0.0.0 $local_port $proxy_ip $proxy_port" >> /etc/rinetd.conf
iptables -I INPUT -p tcp -m state --state NEW -m tcp --dport $local_port -j ACCEPT
iptables -I INPUT -p udp -m state --state NEW -m udp --dport $local_port -j ACCEPT
sleep 3
service rinetd restart
}

function gogogo(){
if command -v rinetd >/dev/null 2>&1; then 
  run
else 
  echo '先安装Gost' 
  install_rinetd
  run
fi
}

[[ $1 ==  "list" ]] && list
[[ $1 ==  "" ]] && gogogo
