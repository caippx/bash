#!/bin/bash

apt update
apt install -y make gcc linux-headers-$(uname -r)

wget -qO /tmp/tcp_bbr.c "https://raw.githubusercontent.com/caippx/bash/master/vvr/v2/src/$(uname -r |cut -d"-" -f1 |cut -d"." -f1-1).x/tcp_bbr.c"
wget -qO /tmp/Makefile "https://raw.githubusercontent.com/caippx/bash/master/vvr/v2/Makefile"
cd /tmp/
make && make install
