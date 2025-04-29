if command -v curl >/dev/null 2>&1 && command -v wget >/dev/null 2>&1; then
    echo "curl 和 wget 均已安装"
else
    apt update -y && apt install curl wget -y
fi

if curl --connect-timeout 5 -s https://github.com > /dev/null 2>&1; then
    echo "能够访问 github.com"
    # 如果访问正常，这里使用原始地址
    GITHUB_URL="https://github.com"
else
    echo "无法访问 github.com，使用代理"
    # 如果访问失败，则替换为代理地址
    GITHUB_URL="https://ghproxy.11451185.xyz/github.com"
fi

# 我自己只用64位系统 就不判断是不是32了
arch=$(uname -m)
# 判断是否为 ARM 架构
if [[ "$arch" == "arm"* || "$arch" == "aarch64" ]]; then
    echo "系统为aarch64"
    wget ${GITHUB_URL}/go-gost/gost/releases/download/v3.0.0/gost_3.0.0_linux_arm64.tar.gz && tar -zxvf gost_3.0.0_linux_arm64.tar.gz
    rm -rf LICENSE README.md README_en.md gost_3.0.0_linux_arm64.tar.gz
    mv gost /usr/bin/gost && chmod +x /usr/bin/gost
else
    echo "系统为X86_64"
    wget ${GITHUB_URL}/go-gost/gost/releases/download/v3.0.0/gost_3.0.0_linux_amd64.tar.gz && tar -zxvf gost_3.0.0_linux_amd64.tar.gz
    rm -rf LICENSE README.md README_en.md gost_3.0.0_linux_amd64.tar.gz
    mv gost /usr/bin/gost && chmod +x /usr/bin/gost
fi

user=$1
password=$2

echo '[Unit]
Description=PPX Proxy Sell
After=network.target

[Service]
ExecStart=/usr/bin/gost -L="socks5://'$user':'$password'@:11111?udp=true&keepAlive=true&ttl=10s&readBufferSize=51200" -L="http://'$user':'$password'@:22222?udp=true&keepAlive=true&ttl=10s&readBufferSize=51200"
Restart=always
RestartSec=1
User=root
Group=root
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target' > /etc/systemd/system/proxysell.service
ip=`curl ip.sb -4`
systemctl daemon-reload
systemctl start luodi.service
systemctl enable luodi.service
echo "socks5://$user:$password@$ip:11111"
echo "http://$user:$password@$ip:22222"
#systemctl stop luodi.service
#systemctl restart luodi.service
