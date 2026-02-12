#!/bin/bash




[ ! -f "/lib/modules/$(uname -r)/kernel/net/ipv4/tcp_bbr.ko" ] && echo "Not Support BBR by Default." && echo "默认不支持BBR 请切换支持BBR的内核" && exit 1

installDep=()
for dep in $(echo "gcc,make,curl" |sed 's/,/\n/g'); do command -v "${dep}" >/dev/null || installDep+=("${dep}"); done
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

if curl --connect-timeout 5 -s https://github.com > /dev/null 2>&1; then
    echo "能够访问 github.com"
    # 如果访问正常，这里使用原始地址
    GITHUB_URL="https://"
else
    echo "无法访问 github.com，使用代理"
    # 如果访问失败，则替换为代理地址
    GITHUB_URL="https://ghproxy.11451185.xyz/"
fi

kernelVer=$(uname -r |cut -d- -f1 |cut -d. -f1-2)
[ ! -n "${kernelVer}" ] && echo "No Found Kernel Version." && echo "无法识别内核版本." && exit 1

wget -qO /tmp/tcp_bbr.c "https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git/plain/net/ipv4/tcp_bbr.c?h=v${kernelVer}"
[ $? -ne 0 ] && echo "Invalid Kernel Version." && echo "不支持的内核版本" && exit 1

wget -qO /tmp/Makefile "${GITHUB_URL}raw.githubusercontent.com/caippx/bash/master/vvr/v2/Makefile"
[ $? -ne 0 ] && echo "Invalid Make File." && echo "编译文件下载错误" && exit 1


# bbr_min_rtt_win_sec
sed -i 's|static const u32 bbr_min_rtt_win_sec[^;]*;|static const u32 bbr_min_rtt_win_sec = 13;|g' /tmp/tcp_bbr.c

# bbr_probe_rtt_mode_ms
sed -i 's|static const u32 bbr_probe_rtt_mode_ms[^;]*;|static const u32 bbr_probe_rtt_mode_ms = 56;|g' /tmp/tcp_bbr.c

# bbr_pacing_gain
sed -i '1h;1!H;$!d;${g;s|static const int bbr_pacing_gain\[\][^;]*;|static const int bbr_pacing_gain[] = \{\n        BBR_UNIT * 16 / 8,\n        BBR_UNIT * 6 / 8,\n        BBR_UNIT * 16 / 8,        BBR_UNIT * 10 / 8,        BBR_UNIT * 14 / 8,\n        BBR_UNIT * 10 / 8,        BBR_UNIT * 12 / 8,        BBR_UNIT * 10 / 8\n\};|g;}' /tmp/tcp_bbr.c

# bbr_full_bw_thresh
sed -i 's|static const u32 bbr_full_bw_thresh[^;]*;|static const u32 bbr_full_bw_thresh = BBR_UNIT * 18 / 16;|g' /tmp/tcp_bbr.c

# bbr_lt_bw
sed -i 's|static const u32 bbr_lt_bw_max_rtts[^;]*;|static const u32 bbr_lt_bw_max_rtts = 4;|g' /tmp/tcp_bbr.c
sed -i 's|static const u32 bbr_lt_bw_ratio[^;]*;|static const u32 bbr_lt_bw_ratio = BBR_UNIT / 16;|g' /tmp/tcp_bbr.c
sed -i 's|static const u32 bbr_lt_bw_diff[^;]*;|static const u32 bbr_lt_bw_diff = 8000 / 8;|g' /tmp/tcp_bbr.c

# mark
sed -i 's|^MODULE_DESCRIPTION([^;]*;|MODULE_DESCRIPTION("TCP BBR (Bottleneck Bandwidth and RTT) [SV: '$(date +%Y/%m/%d)' Installed]");|g' /tmp/tcp_bbr.c


# makefile
cat >/tmp/Makefile<<EOF
obj-m := tcp_bbr.o

all:
	make -C /lib/modules/\`uname -r\`/build M=\`pwd\` modules CC=\`which gcc\`
	
clean:
	make -C /lib/modules/\`uname -r\`/build M=\`pwd\` clean

sysctlDel:
	sed -i '/net\.core\.default_qdisc/d' /etc/sysctl.conf
	sed -i '/net\.ipv4\.tcp_congestion_control/d' /etc/sysctl.conf

sysctlAdd:
	make sysctlDel
	sed -i '\$\$a\net.core.default_qdisc = fq\nnet.ipv4.tcp_congestion_control = bbr\n\n' /etc/sysctl.conf
	sysctl -p

install:
	cp -rf tcp_bbr.ko /lib/modules/\`uname -r\`/kernel/net/ipv4
	insmod /lib/modules/\`uname -r\`/kernel/net/ipv4/tcp_bbr.ko 2>/dev/null || true
	depmod -a
	make sysctlAdd

uninstall:
	rm -rf /lib/modules/\`uname -r\`/kernel/net/ipv4/tcp_bbr.ko
	make sysctlDel

EOF

cd /tmp
make && make install

sysctl -p
