#!/bin/bash

echo && stty erase '^H' && read -p "输入安装的版本(0,1,2): " ver
[[ -z ${ver} ]] && ver="0"
bash <(wget --no-check-certificate -qO- "https://raw.githubusercontent.com/MoeClub/BBR/master/install.sh")
cd /lib/modules/4.14.153/kernel/net/ipv4
wget --no-check-certificate -qO "tcp_bbr.ko" "https://raw.githubusercontent.com/caippx/bash/master/vvr/v${ver}/tcp_bbr.ko"
echo 'Setting: limits.conf'
[ -f /etc/security/limits.conf ] && LIMIT='262144' && sed -i '/^\(\*\|root\)[[:space:]]*\(hard\|soft\)[[:space:]]*\(nofile\|memlock\)/d' /etc/security/limits.conf && echo -ne "*\thard\tmemlock\t${LIMIT}\n*\tsoft\tmemlock\t${LIMIT}\nroot\thard\tmemlock\t${LIMIT}\nroot\tsoft\tmemlock\t${LIMIT}\n*\thard\tnofile\t${LIMIT}\n*\tsoft\tnofile\t${LIMIT}\nroot\thard\tnofile\t${LIMIT}\nroot\tsoft\tnofile\t${LIMIT}\n\n" >>/etc/security/limits.conf
echo 'Setting: sysctl.conf'
cat >>/etc/sysctl.conf<<EOF
# This line below add by user.
fs.file-max = 104857600
fs.nr_open = 1048576
vm.overcommit_memory = 1
net.ipv4.ip_forward = 1
net.core.somaxconn = 4096
net.core.optmem_max = 262144
net.core.rmem_max = 8388608
net.core.wmem_max = 8388608
net.core.rmem_default = 262144
net.core.wmem_default = 262144
net.core.netdev_max_backlog = 65536
net.ipv4.tcp_mem = 262144 6291456 8388608
net.ipv4.tcp_rmem = 16384 262144 8388608
net.ipv4.tcp_wmem = 8192 262144 8388608
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_syn_retries = 4
net.ipv4.tcp_synack_retries = 3
net.ipv4.tcp_max_syn_backlog = 4096
net.ipv4.tcp_fin_timeout = 24
net.ipv4.tcp_keepalive_intvl = 32
net.ipv4.tcp_keepalive_probes = 3
net.ipv4.tcp_keepalive_time = 900
net.ipv4.tcp_retries1 = 3
net.ipv4.tcp_retries2 = 8
net.ipv4.tcp_timestamps = 1
net.ipv4.tcp_slow_start_after_idle = 0
# net.ipv4.tcp_fastopen = 3
EOF
echo "安装完毕~准备重启应用！用sysctl -p查看是否启用成功"
sleep 2
reboot
