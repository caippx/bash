#!/bin/bash

function install_gost(){

if command -v curl >/dev/null 2>&1 && command -v wget >/dev/null 2>&1; then
    echo "curl 和 wget 均已安装"
else
    apt update -y && apt install curl wget -y
fi

if curl --connect-timeout 5 -s https://github.com > /dev/null 2>&1; then
    echo "能够访问 github.com"
    # 如果访问正常，这里使用原始地址
    GITHUB_URL="https://github.com"
else
    echo "无法访问 github.com，使用代理"
    # 如果访问失败，则替换为代理地址
    GITHUB_URL="https://ghproxy.11451185.xyz/github.com"
fi

# 我自己只用64位系统 就不判断是不是32了
arch=$(uname -m)
# 判断是否为 ARM 架构
if [[ "$arch" == "arm"* || "$arch" == "aarch64" ]]; then
    echo "系统为aarch64"
    wget ${GITHUB_URL}/go-gost/gost/releases/download/v3.0.0/gost_3.0.0_linux_arm64.tar.gz && tar -zxvf gost_3.0.0_linux_arm64.tar.gz
    rm -rf LICENSE README.md README_en.md gost_3.0.0_linux_arm64.tar.gz
    mv gost /usr/bin/gost && chmod +x /usr/bin/gost
else
    echo "系统为X86_64"
    wget ${GITHUB_URL}/go-gost/gost/releases/download/v3.0.0/gost_3.0.0_linux_amd64.tar.gz && tar -zxvf gost_3.0.0_linux_amd64.tar.gz
    rm -rf LICENSE README.md README_en.md gost_3.0.0_linux_amd64.tar.gz
    mv gost /usr/bin/gost && chmod +x /usr/bin/gost
fi
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
sleep 3
a=`ps -aux|grep $!| grep -v grep`
[[ -n ${a} ]] && echo "启动成功！进程ID：$!"
[[ -z ${a} ]] && echo "启动失败，请自己找错误 嘻嘻"
echo "nohup gost -L=tcp://:$local_port/$proxy_ip:$proxy_port >>/dev/null 2>&1 &" >> /root/gost.cmd
echo "nohup gost -L=udp://:$local_port/$proxy_ip:$proxy_port >>/dev/null 2>&1 &" >> /root/gost.cmd

}

function run_ws_zz(){
echo && stty erase '^H' && read -p "输入落地域名: " proxy_ip
echo && stty erase '^H' && read -p "输入落地端口: " proxy_port
echo && stty erase '^H' && read -p "输入本地端口: " local_port
nohup gost -L udp://:$local_port -L tcp://:$local_port -F relay+ws://$proxy_ip:$proxy_port >>/dev/null 2>&1 &
sleep 3
a=`ps -aux|grep $!| grep -v grep`
[[ -n ${a} ]] && echo "启动成功！进程ID：$!"
[[ -z ${a} ]] && echo "启动失败，请自己找错误 嘻嘻"
echo "nohup gost -L udp://:$local_port -L tcp://:$local_port -F relay+ws://$proxy_ip:$proxy_port >>/dev/null 2>&1 &" >> /root/gost.cmd
}

function run_ws_luodi(){
echo && stty erase '^H' && read -p "输入远程IP（域名）: " proxy_ip
echo && stty erase '^H' && read -p "输入远程端口: " proxy_port
echo && stty erase '^H' && read -p "输入本地端口: " local_port
nohup gost -L "relay+ws://:$local_port/$proxy_ip:$proxy_port" >> /dev/null 2>&1 &
sleep 3
a=`ps -aux|grep $!| grep -v grep`
[[ -n ${a} ]] && echo "启动成功！进程ID：$!"
[[ -z ${a} ]] && echo "启动失败，请自己找错误 嘻嘻"
echo "nohup gost -L \"relay+ws://:$local_port/$proxy_ip:$proxy_port\" >> /dev/null 2>&1 &" >> /root/gost.cmd
}

function run_wss_zz(){
echo && stty erase '^H' && read -p "输入落地域名: " proxy_ip
echo && stty erase '^H' && read -p "输入落地端口: " proxy_port
echo && stty erase '^H' && read -p "输入本地端口: " local_port
nohup gost -L udp://:$local_port -L tcp://:$local_port -F relay+wss://$proxy_ip:$proxy_port >>/dev/null 2>&1 &
sleep 3
a=`ps -aux|grep $!| grep -v grep`
[[ -n ${a} ]] && echo "启动成功！进程ID：$!"
[[ -z ${a} ]] && echo "启动失败，请自己找错误 嘻嘻"
echo "nohup gost -L udp://:$local_port -L tcp://:$local_port -F relay+wss://$proxy_ip:$proxy_port >>/dev/null 2>&1 &" >> /root/gost.cmd
}

function run_wss_luodi(){
echo && stty erase '^H' && read -p "输入远程IP（域名）: " proxy_ip
echo && stty erase '^H' && read -p "输入远程端口: " proxy_port
echo && stty erase '^H' && read -p "输入本地端口: " local_port
if [ -d "/gost_cert" ]; then
  nohup gost -L "relay+wss://:$local_port/$proxy_ip:$proxy_port?certFile=/gost_cert/cert.pem&keyFile=/gost_cert/key.pem" >> /dev/null 2>&1 &
else
  echo '证书不存在'
  exit
fi
sleep 3
a=`ps -aux|grep $!| grep -v grep`
[[ -n ${a} ]] && echo "启动成功！进程ID：$!"
[[ -z ${a} ]] && echo "启动失败，请自己找错误 嘻嘻"
echo "nohup gost -L \"relay+wss://:$local_port/$proxy_ip:$proxy_port?certFile=/gost_cert/cert.pem&keyFile=/gost_cert/key.pem\" >> /dev/null 2>&1 &" >> /root/gost.cmd
}

function what_to_do(){
  echo -e "请问您要设置的传输类型: "
  echo -e "-----------------------------------"
  echo -e "[1] 不加密转发"
  echo -e "[2] ws隧道中转设置"
  echo -e "[3] ws隧道落地设置"
  echo -e "[4] wss隧道中转设置"
  echo -e "[5] wss隧道落地设置"
  echo -e "注意: 同一则转发，中转与落地传输类型必须对应！"
  echo -e "此功能只需在中转机设置"
  echo -e "-----------------------------------"
  read -p "请选择转发传输类型: " dowhat
  if [ "$dowhat" == "1" ]; then
    run
  elif [ "$dowhat" == "2" ]; then
    run_ws_zz
  elif [ "$dowhat" == "3" ]; then
    run_ws_luodi
  elif [ "$dowhat" == "4" ]; then
    run_wss_zz
  elif [ "$dowhat" == "5" ]; then
    run_wss_luodi
  else
    echo "输入错误"
    exit
  fi

}

function gogogo(){
if command -v gost >/dev/null 2>&1; then 
  what_to_do
else 
  echo '先安装Gost' 
  install_gost
  what_to_do
fi
}

[[ $1 ==  "list" ]] && list
[[ $1 ==  "" ]] && gogogo


#gost -L ss://chacha20-ietf-poly1305:password@:60000
#gost -L tcp://:33010/xxx:3010 -F ss://chacha20-ietf-poly1305:password@192.168.0.4:60000
