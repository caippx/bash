#!/bin/bash

[ "$EUID" -ne '0' ] && echo "Error:This script must be run as root!" && exit 1;

echo "Download: linux-image-4.14.153_4.14.153-1_amd64.deb"
wget --no-check-certificate -qO '/tmp/linux-image-4.14.153_4.14.153-1_amd64.deb' 'https://ghproxy.com/https://github.com/MoeClub/BBR/releases/latest/download/linux-image-4.14.153_4.14.153-1_amd64.deb'
dpkg -i '/tmp/linux-image-4.14.153_4.14.153-1_amd64.deb'
[ $? -eq 0 ] || exit 1 

sed -i '/net\.core\.default_qdisc/d' /etc/sysctl.conf
sed -i '/net\.ipv4\.tcp_congestion_control/d' /etc/sysctl.conf
while [ -z "$(sed -n '$p' /etc/sysctl.conf)" ]; do sed -i '$d' /etc/sysctl.conf; done
sed -i '$a\net.core.default_qdisc=fq\nnet.ipv4.tcp_congestion_control=bbr\n\n' /etc/sysctl.conf

item="linux-image-4.14.153"
while true; do
  List_Kernel="$(dpkg -l |grep 'linux-image\|linux-modules\|linux-generic\|linux-headers' |grep -v "${item}")"
  Num_Kernel="$(echo "$List_Kernel" |sed '/^$/d' |wc -l)"
  [ "$Num_Kernel" -eq "0" ] && break
  for kernel in `echo "$List_Kernel" |awk '{print $2}'`
    do
      if [ -f "/var/lib/dpkg/info/${kernel}.prerm" ]; then
        sed -i 's/linux-check-removal/#linux-check-removal/' "/var/lib/dpkg/info/${kernel}.prerm"
        sed -i 's/uname -r/echo purge/' "/var/lib/dpkg/info/${kernel}.prerm"
      fi
      dpkg --force-depends --purge "$kernel"
    done
  done
apt-get autoremove -y

echo -e "\n\nPlease reboot it...\n"

cd /lib/modules/4.14.153/kernel/net/ipv4
wget --no-check-certificate -qO "tcp_bbr.ko" "https://ghproxy.com/https://raw.githubusercontent.com/caippx/bash/master/vvr/v0/tcp_bbr.ko"
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
