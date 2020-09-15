#!/bin/bash

apt install curl git -y
curl -SL https://gitee.com/skiy/golang-install/raw/master/install.sh | bash /dev/stdin -v 1.13.6
source /root/.bashrc
git clone https://github.com/caippx/SimpleSNIProxy.git
cd SimpleSNIProxy && go mod init github.com/caippx/SimpleSNIProxy && go build
mv SimpleSNIProxy /usr/local/bin/sniproxy
chmod +x /usr/local/bin/sniproxy
nohup sniproxy >> /tmp/sniproxy.log 2>&1 &
