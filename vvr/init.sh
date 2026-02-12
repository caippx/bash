#!/bin/bash

DEBIAN_FRONTEND=noninteractive apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends openssl net-tools dnsutils nload curl wget lsof psmisc

if [ -d /etc/systemd ]; then
  # systemd-journald
  if [ -f /etc/systemd/journald.conf ]; then
    sed -i 's/^#\?Storage=.*/Storage=volatile/' /etc/systemd/journald.conf
    sed -i 's/^#\?SystemMaxUse=.*/SystemMaxUse=8M/' /etc/systemd/journald.conf
    sed -i 's/^#\?RuntimeMaxUse=.*/RuntimeMaxUse=8M/' /etc/systemd/journald.conf
    sed -i 's/^#\?ForwardToSyslog=.*/ForwardToSyslog=no/' /etc/systemd/journald.conf
    systemctl restart systemd-journald 2>/dev/null
  fi
  # systemd-timesyncd
  if [ -f /etc/systemd/timesyncd.conf ]; then
    echo -ne "[Time]\nNTP=time.apple.com time.windows.com pool.ntp.org ntp.ntsc.ac.cn\nRootDistanceMaxSec=3\nPollIntervalMinSec=24\nPollIntervalMaxSec=512\n\n" >/etc/systemd/timesyncd.conf
    systemctl restart systemd-timesyncd 2>/dev/null
  fi
  # systemd
  if [ -f /etc/systemd/system.conf ]; then
    sed -i 's/#\?DefaultLimitNOFILE=.*/DefaultLimitNOFILE=262144/' /etc/systemd/system.conf
    sed -i 's/#\?DefaultLimitMEMLOCK=.*/DefaultLimitMEMLOCK=262144/' /etc/systemd/system.conf
    sed -i 's/#\?DefaultTasksMax=.*/DefaultTasksMax=65535/' /etc/systemd/system.conf
    if [ -f /etc/systemd/user.conf ]; then
      sed -i 's/#\?DefaultLimitNOFILE=.*/DefaultLimitNOFILE=262144/' /etc/systemd/user.conf
      sed -i 's/#\?DefaultLimitMEMLOCK=.*/DefaultLimitMEMLOCK=262144/' /etc/systemd/user.conf
    fi
    systemctl daemon-reexec
  fi
fi

# limits
if [ -f /etc/security/limits.conf ]; then
  LIMIT='262144'
  sed -i '/^\(\*\|root\)[[:space:]]*\(hard\|soft\)[[:space:]]*\(nofile\|memlock\)/d' /etc/security/limits.conf
  echo -ne "*\thard\tmemlock\t${LIMIT}\n*\tsoft\tmemlock\t${LIMIT}\nroot\thard\tmemlock\t${LIMIT}\nroot\tsoft\tmemlock\t${LIMIT}\n*\thard\tnofile\t${LIMIT}\n*\tsoft\tnofile\t${LIMIT}\nroot\thard\tnofile\t${LIMIT}\nroot\tsoft\tnofile\t${LIMIT}\n\n" >>/etc/security/limits.conf
fi

# root
sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin yes/g' /etc/ssh/sshd_config;
sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication yes/g' /etc/ssh/sshd_config;
rm -rf /etc/ssh/sshd_config.d/*;

# timezone
ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && echo "Asia/Shanghai" >/etc/timezone

# ssh
[ -d ~/.ssh ] || mkdir -p ~/.ssh
echo -ne "# chmod 600 ~/.ssh/id_rsa\n\nHost *\n  StrictHostKeyChecking no\n  UserKnownHostsFile /dev/null\n  IdentityFile ~/.ssh/id_rsa\n" > ~/.ssh/config

# nload
echo -ne 'DataFormat="Human Readable (Byte)"\nTrafficFormat="Human Readable (Byte)"\n' >/etc/nload.conf

# sysctl
Bandwidth="${1:-1000}"   # MB
RTT="${2:-192}"           # ms
BDP=`echo "${Bandwidth} ${RTT}" |awk '{printf "%d", ($1 * $2) * ((1024 * 1024) / (1000 * 8))}' 2>/dev/null`
[ -n "${BDP}" ] && [ "${BDP}" -gt "262144" ] || BDP="262144"

cat >/etc/sysctl.conf<<EOF
# This line below add by auto.

kernel.pid_max = 65536
kernel.sched_autogroup_enabled = 0

fs.file-max = 104857600
fs.aio-max-nr = 10485760
fs.nr_open = 10485760
fs.inotify.max_user_instances = 102400
fs.inotify.max_user_watches = 10485760
fs.inotify.max_queued_events = 327680

vm.overcommit_memory = 0
vm.oom_kill_allocating_task = 1
vm.min_free_kbytes = 16384
vm.zone_reclaim_mode = 0
vm.swappiness = 10

net.core.default_qdisc = fq
net.core.netdev_max_backlog = 262144
net.core.somaxconn = 131072
net.core.optmem_max = 32768
net.core.rmem_default = 262144
net.core.wmem_default = 262144
net.core.rmem_max = ${BDP}
net.core.wmem_max = ${BDP}
net.core.busy_poll = 0
net.core.busy_read = 0

net.ipv4.ip_forward = 1
net.ipv4.tcp_congestion_control = bbr
net.ipv4.tcp_mem = 262144 648020 1048576
net.ipv4.tcp_rmem = 4096 131072 25165824
net.ipv4.tcp_wmem = 4096 16384 25165824
net.ipv4.tcp_max_syn_backlog = 65535
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_syn_retries = 5
net.ipv4.tcp_synack_retries = 5
net.ipv4.tcp_retries1 = 3
net.ipv4.tcp_retries2 = 8
net.ipv4.tcp_fin_timeout = 12
net.ipv4.tcp_keepalive_intvl = 15
net.ipv4.tcp_keepalive_probes = 4
net.ipv4.tcp_keepalive_time = 240
net.ipv4.tcp_no_metrics_save = 1
net.ipv4.tcp_timestamps = 1
net.ipv4.tcp_adv_win_scale = 3
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_moderate_rcvbuf = 1
net.ipv4.tcp_slow_start_after_idle = 1
net.ipv4.tcp_mtu_probing = 1
net.ipv4.tcp_fastopen = 0
net.ipv4.tcp_fack = 1
net.ipv4.tcp_sack = 1
net.ipv4.tcp_dsack = 1
net.ipv4.tcp_ecn = 0
net.ipv4.tcp_ecn_fallback = 1

net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0

net.ipv6.conf.all.disable_ipv6 = 0
net.ipv6.conf.all.forwarding = 1
net.ipv6.conf.all.accept_ra = 2
net.ipv6.conf.all.proxy_ndp = 1




EOF
sysctl -p
sysctl -w net.ipv4.route.flush=1
