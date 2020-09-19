#!/bin/bash
#一个垃圾 V2ray安装脚本 

ver="$(echo `curl "https://api.github.com/repos/v2fly/v2ray-core/releases/latest"` | grep 'tag_name' | awk -F '"' '{print $26}')"
download_url="https://github.com/v2fly/v2ray-core/releases/download/${ver}/v2ray-linux-64.zip"
mkdir -p /tmp/v2ray-linux-64/
wget -O /tmp/v2ray-linux-64/v2ray.zip $download_url && cd /tmp/v2ray-linux-64/ && unzip /tmp/v2ray-linux-64/v2ray.zip
mv /tmp/v2ray-linux-64/v2ctl /usr/local/bin/ && mv /tmp/v2ray-linux-64/v2ray /usr/local/bin/
mkdir -p /usr/local/share/v2ray/ && mv /tmp/v2ray-linux-64/*.dat /usr/local/share/v2ray/
mkdir -p /usr/local/etc/v2ray/ && mv /tmp/v2ray-linux-64/*.json /usr/local/etc/v2ray/
mkdir -p /var/log/v2ray/ && touch /var/log/v2ray/access.log && touch /var/log/v2ray/error.log
cat > "/etc/systemd/system/v2ray.service" <<-EOF
[Unit]
Description=V2Ray Service
After=network.target nss-lookup.target

[Service]
User=root
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=true
Environment=V2RAY_LOCATION_ASSET=/usr/local/share/v2ray/
ExecStart=/usr/local/bin/v2ray -config /usr/local/etc/v2ray/config.json
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

cat > "/etc/systemd/system/v2ray@.service" <<-EOF
[Unit]
Description=V2Ray Service
After=network.target nss-lookup.target

[Service]
User=root
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=true
Environment=V2RAY_LOCATION_ASSET=/usr/local/share/v2ray/
ExecStart=/usr/local/bin/v2ray -config /usr/local/etc/v2ray/%i.json
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
chmod +x /etc/systemd/system/v2ray@.service /etc/systemd/system/v2ray.service /usr/local/bin/v2ray /usr/local/bin/v2ctl
rm -rf /tmp/v2ray*
systemctl daemon-reload

echo "
V2ray 安装位置/usr/local/bin/
Dat 位置 /usr/local/share/v2ray/
日志地址 /var/log/v2ray/
配置文件位置 /usr/local/etc/v2ray/
"
