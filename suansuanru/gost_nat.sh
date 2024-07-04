#!/bin/bash

function install_gost(){
echo "自动安装只适应x64"
wget https://github.com/go-gost/gost/releases/download/v3.0.0-nightly.20240625/gost_3.0.0-nightly.20240625_linux_amd64.tar.gz && tar -zxvf gost_3.0.0-nightly.20240625_linux_amd64.tar.gz
rm -rf LICENSE README.md README_en.md gost_3.0.0-nightly.20240625_linux_amd64.tar.gz
mv gost /usr/bin/gost && chmod +x /usr/bin/gost
}

function list(){
ps -ef | grep -v grep | grep "gost"
}

function run(){
echo && stty erase '^H' && read -p "输入远程IP（域名）: " proxy_ip
echo && stty erase '^H' && read -p "输入远程端口: " proxy_port
echo && stty erase '^H' && read -p "输入本地端口: " local_port
nohup gost -L=tcp://:$local_port/$proxy_ip:$proxy_port >>/dev/null 2>&1 &
nohup gost -L=udp://:$local_port/$proxy_ip:$proxy_port >>/dev/null 2>&1 &
iptables -I INPUT -p tcp -m state --state NEW -m tcp --dport $local_port -j ACCEPT
iptables -I INPUT -p udp -m state --state NEW -m udp --dport $local_port -j ACCEPT
sleep 3
a=`ps -aux|grep $!| grep -v grep`
[[ -n ${a} ]] && echo "启动成功！进程ID：$!"
[[ -z ${a} ]] && echo "启动失败，请自己找错误 嘻嘻"
echo "nohup gost -L=tcp://:$local_port/$proxy_ip:$proxy_port >>/dev/null 2>&1 &" >> /root/gost.cmd
echo "nohup gost -L=udp://:$local_port/$proxy_ip:$proxy_port >>/dev/null 2>&1 &" >> /root/gost.cmd
}

function gogogo(){
if command -v gost >/dev/null 2>&1; then 
  run
else 
  echo '先安装Gost' 
  install_gost
  run
fi
}

[[ $1 ==  "list" ]] && list
[[ $1 ==  "" ]] && gogogo
