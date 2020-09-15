#!/bin/bash

#配置v2ray 各种

config="/usr/local/etc/v2ray/config.json"
o_uuid="$(cat $config | grep 'id' | awk -F '"' '{print $4}')"
o_port="$(cat $config | grep '"port"' | awk -F ' ' '{print $2}' | awk -F ',' '{print $1}')"
uuid=`uuid`
echo && stty erase '^H' && read -p "输入端口号[1-65535]" port
sed -i "s/$o_uuid/$uuid/" $config
sed -i "s/$o_port/$port/" $config
