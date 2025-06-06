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
sudo cp /etc/sysctl.conf /etc/sysctl.conf.bk_$(date +%Y%m%d_%H%M%S) && sudo sh -c 'echo "kernel.pid_max = 65535
kernel.panic = 1
kernel.sysrq = 1
kernel.core_pattern = core_%e
kernel.printk = 3 4 1 3
kernel.numa_balancing = 0
kernel.sched_autogroup_enabled = 0

vm.swappiness = 10
vm.dirty_ratio = 10
vm.dirty_background_ratio = 5
vm.panic_on_oom = 1
vm.overcommit_memory = 1
vm.min_free_kbytes = 153600

net.core.default_qdisc = cake
net.core.netdev_max_backlog = 2000
net.core.rmem_max = 78643200
net.core.wmem_max = 39321600
net.core.rmem_default = 87380
net.core.wmem_default = 65536
net.core.somaxconn = 500
net.core.optmem_max = 65536

net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_timestamps = 1
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 10
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.tcp_max_tw_buckets = 32768
net.ipv4.tcp_sack = 1
net.ipv4.tcp_fack = 0

net.ipv4.tcp_rmem = 8192 87380 78643200
net.ipv4.tcp_wmem = 8192 65536 39321600
net.ipv4.tcp_mtu_probing = 1
net.ipv4.tcp_congestion_control = bbr
net.ipv4.tcp_notsent_lowat = 4096
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_adv_win_scale = 2
net.ipv4.tcp_moderate_rcvbuf = 1
net.ipv4.tcp_no_metrics_save = 0
net.ipv4.tcp_init_cwnd = undefined

net.ipv4.tcp_max_syn_backlog = 2048
net.ipv4.tcp_max_orphans = 65536
net.ipv4.tcp_synack_retries = 2
net.ipv4.tcp_syn_retries = 3
net.ipv4.tcp_abort_on_overflow = 0
net.ipv4.tcp_stdurg = 0
net.ipv4.tcp_rfc1337 = 0
net.ipv4.tcp_syncookies = 1

net.ipv4.ip_local_port_range = 1024 65535
net.ipv4.ip_no_pmtu_disc = 0
net.ipv4.route.gc_timeout = 100
net.ipv4.neigh.default.gc_stale_time = 120
net.ipv4.neigh.default.gc_thresh3 = 8192
net.ipv4.neigh.default.gc_thresh2 = 4096
net.ipv4.neigh.default.gc_thresh1 = 1024

net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.icmp_ignore_bogus_error_responses = 1
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
net.ipv4.conf.all.arp_announce = 2
net.ipv4.conf.default.arp_announce = 2
net.ipv4.conf.all.arp_ignore = 1
net.ipv4.conf.default.arp_ignore = 1" > /etc/sysctl.conf' && sudo sysctl -p
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

user=$1
password=$2

echo '[Unit]
Description=PPX Proxy Sell
After=network.target

[Service]
ExecStart=/usr/bin/gost -L="socks5://'$user':'$password'@:11111?udp=true&keepAlive=true&ttl=10s&readBufferSize=51200" -L="http://'$user':'$password'@:22222?udp=true&keepAlive=true&ttl=10s&readBufferSize=51200"
Restart=always
RestartSec=1
User=root
Group=root
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target' > /etc/systemd/system/proxysell.service
ip=`curl ip.sb -4`
systemctl daemon-reload
systemctl start proxysell.service
systemctl enable proxysell.service
echo "socks5://$user:$password@$ip:11111"
echo "http://$user:$password@$ip:22222"
#systemctl stop luodi.service
#systemctl restart luodi.service
