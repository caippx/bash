#!/bin/bash

echo && stty erase '^H' && read -p "输入安装的版本(0,1,2): " ver
[[ -z ${ver} ]] && ver="0"
bash <(wget --no-check-certificate -qO- "https://raw.githubusercontent.com/MoeClub/BBR/master/install.sh")
cd /lib/modules/4.14.153/kernel/net/ipv4
wget --no-check-certificate -qO "tcp_bbr.ko" "https://raw.githubusercontent.com/caippx/bash/master/vvr/v${ver}/tcp_bbr.ko"
echo "安装完毕~准备重启应用！用sysctl -p查看是否启用成功"
sleep 2
reboot
