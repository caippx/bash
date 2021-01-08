#!/bin/bash

#把宝塔自签ssl证书修改为免费的信任ip证书

ip=`curl -s http://whatismyip.akamai.com/`

ssl_dir="/www/server/panel/vhost/ssl/$ip"
bt_ssl_dir="/www/server/panel/ssl"


crt=`cat $ssl_dir/fullchain.pem`
key=`cat $ssl_dir/privkey.pem`

echo "$crt" > $bt_ssl_dir/certificate.pem
echo "$key" > $bt_ssl_dir/privateKey.pem

echo "6677" > /www/server/panel/data/port.pl

bt restart
