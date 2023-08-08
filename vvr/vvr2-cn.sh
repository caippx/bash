#!/bin/bash

[ ! -f "/lib/modules/$(uname -r)/kernel/net/ipv4/tcp_bbr.ko" ] && echo "Not Support BBR by Default." && echo "默认不支持BBR 请切换支持BBR的内核" && exit 1

installDep=()
for dep in $(echo "gcc,make" |sed 's/,/\n/g'); do command -v "${dep}" >/dev/null || installDep+=("${dep}"); done
ls -1 "/usr/src" |grep -q "^linux-headers-$(uname -r)" || installDep+=("linux-headers-$(uname -r)")

if [ "${#installDep[@]}" -gt 0 ]; then
  apt update
  apt install -y "${installDep[@]}"
  if [ $? -ne 0 ]; then
    echo "Install Package Fail."
    echo "安装依赖失败."
    exit 1
  fi
fi

kernelVer=$(uname -r |cut -d- -f1 |cut -d. -f1-2)
[ ! -n "${kernelVer}" ] && echo "No Found Kernel Version." && echo "无法识别内核版本." && exit 1

wget -qO /tmp/tcp_bbr.c "https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git/plain/net/ipv4/tcp_bbr.c?h=v${kernelVer}"
[ $? -ne 0 ] && echo "Invalid Kernel Version." && echo "不支持的内核版本" && exit 1

wget -qO /tmp/Makefile "https://raw.githubusercontent.com/caippx/bash/master/vvr/v2/Makefile"
[ $? -ne 0 ] && echo "Invalid Make File." && echo "编译文件下载错误" && exit 1


# bbr_min_rtt_win_sec
sed -i 's|static const u32 bbr_min_rtt_win_sec[^;]*;|static const u32 bbr_min_rtt_win_sec = 13;|g' /tmp/tcp_bbr.c

# bbr_probe_rtt_mode_ms
sed -i 's|static const u32 bbr_probe_rtt_mode_ms[^;]*;|static const u32 bbr_probe_rtt_mode_ms = 56;|g' /tmp/tcp_bbr.c

# bbr_min_tso_rate
sed -i 's|static const int bbr_min_tso_rate[^;]*;|static const int bbr_min_tso_rate = 256000;|g' /tmp/tcp_bbr.c

# bbr_gain
sed -i 's|static const int bbr_high_gain[^;]*;|static const int bbr_high_gain = BBR_UNIT * (2885 * 2) / 1000 + 1;|g' /tmp/tcp_bbr.c
sed -i 's|static const int bbr_drain_gain[^;]*;|static const int bbr_drain_gain = BBR_UNIT * 2 * 1000 / 2885;|g' /tmp/tcp_bbr.c

# bbr_pacing_gain
sed -i '1h;1!H;$!d;${g;s|static const int bbr_pacing_gain\[\][^;]*;|static const int bbr_pacing_gain[] = \{\n        BBR_UNIT * 16 / 8,\n        BBR_UNIT * 6 / 8,\n        BBR_UNIT * 16 / 8,        BBR_UNIT * 10 / 8,        BBR_UNIT * 14 / 8,\n        BBR_UNIT * 10 / 8,        BBR_UNIT * 12 / 8,        BBR_UNIT * 10 / 8\n\};|g;}' /tmp/tcp_bbr.c

# bbr_full_bw_thresh
sed -i 's|static const u32 bbr_full_bw_thresh[^;]*;|static const u32 bbr_full_bw_thresh = BBR_UNIT * 17 / 16;|g' /tmp/tcp_bbr.c

# bbr_lt_bw
sed -i 's|static const u32 bbr_lt_bw_ratio[^;]*;|static const u32 bbr_lt_bw_ratio = BBR_UNIT / 4;|g' /tmp/tcp_bbr.c
sed -i 's|static const u32 bbr_lt_bw_diff[^;]*;|static const u32 bbr_lt_bw_diff = 8000 / 8;|g' /tmp/tcp_bbr.c

# mark
sed -i '$s|");| [ Vicer Violence RTT ] (WR V2.0)");|g' /tmp/tcp_bbr.c

cd /tmp
make && make install

echo "
fs.file-max = 104857600
fs.nr_open = 1048576
vm.overcommit_memory = 1
vm.swappiness = 10
net.core.somaxconn = 65535
net.core.optmem_max = 1048576
net.core.rmem_max = 8388608
net.core.wmem_max = 8388608
net.core.rmem_default = 1048576
net.core.wmem_default = 1048576
net.core.netdev_max_backlog = 65536
net.ipv4.tcp_mem = 2097152 8388608 16777216 
net.ipv4.tcp_rmem = 16384 524288 16777216
net.ipv4.tcp_wmem = 16384 524288 16777216
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_syn_retries = 3
net.ipv4.tcp_synack_retries = 2
net.ipv4.tcp_max_syn_backlog = 65535
net.ipv4.tcp_fin_timeout = 16
net.ipv4.tcp_keepalive_intvl = 32
net.ipv4.tcp_keepalive_probes = 3
net.ipv4.tcp_keepalive_time = 900
net.ipv4.tcp_retries1 = 3
net.ipv4.tcp_retries2 = 8
net.ipv4.tcp_no_metrics_save = 1
net.ipv4.tcp_timestamps = 1
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.ip_forward = 1
net.ipv4.tcp_fastopen = 0
net.ipv4.tcp_fack = 1
net.ipv4.tcp_sack = 1
net.ipv4.tcp_dsack = 1
net.ipv4.tcp_ecn = 0
net.ipv4.tcp_ecn_fallback = 1
" >> /etc/sysctl.conf
sysctl -p
