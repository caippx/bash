#!bin/bash

mkdir -p /www/vList/ && cd /www/vList/
wget https://raw.githubusercontent.com/MoeClub/vList/refs/heads/master/index.html
wget https://github.com/MoeClub/vList/raw/refs/heads/master/amd64/linux/vList
echo '
{
  "WorkFolder": "/data",
  "Endpoint": "/",
  "FolderSize": false,
  "AuthItem": "",
  "RedirectItem" : "",
  "IgnoreFile": "",
  "IgnoreFolder": "",
  "HideFile": "",
  "HideFolder": "",
  "WebDAV": true
}
' > /www/vList/config.json

echo '
[Unit]
Description=vList
After=network-online.target
After=local-fs.target
After=dbus.service

[Service]
Type=simple
ExecStart=/www/vList/vList -bind 127.0.0.1 -port 12580 -q
RestartSec=3s
Restart=always

[Install]
WantedBy=multi-user.target
' > /etc/systemd/system/vlist.service

systemctl daemon-reload
systemctl enable vlist.service
systemctl start vlist.service
