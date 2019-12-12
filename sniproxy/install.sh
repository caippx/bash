#!/bin/bash
apt update -y
apt install autotools-dev cdbs debhelper dh-autoreconf dpkg-dev gettext libev-dev libpcre3-dev libudns-dev pkg-config fakeroot devscripts build-essential unzip -y
mkdir sniproxy && cd sniproxy
wget -N --no-check-certificate https://github.com/dlundquist/sniproxy/archive/master.zip
unzip master.zip && cd sniproxy-master
./autogen.sh && dpkg-buildpackage
sniproxy_deb=$(ls ..|grep "sniproxy_.*.deb") && echo ${sniproxy_deb}
[[ ! -z ${sniproxy_deb} ]] && dpkg -i ../${sniproxy_deb}

echo "user daemon
pidfile /var/run/sniproxy.pid
 
listen 443 {
 proto tls
 table https_hosts
 access_log {
  filename /var/log/sniproxy/https_access.log
  priority notice
 }
}
table https_hosts {
 .* *:443
}
" > /etc/sniproxy.conf
