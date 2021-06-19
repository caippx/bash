#!/bin/bash
host=$1
echo '    "'$host'": "'$host':443"' >> /usr/local/config.yaml
killall -9 sniproxy
sniproxy -c /usr/local/config.yaml
