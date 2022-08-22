#!/bin/bash

# Check if user is root
if [ $(id -u) != "0" ]; then
    echo "Error: You must be root to run this script, please use root to install"
    exit 1
fi

# Check arch
get_arch=`arch`
if [[ $get_arch =~ "x86_64" ]];then
    arch_type="amd64"
elif [[ $get_arch =~ "aarch64" ]];then
    arch_type="arm64"
else
    echo "Error: Only supports amd64 and arm64 architecture machines."
    exit 1
fi

# Download && Replace
file_name="npool_${arch_type}_latest"
if test -f "config.json"
then
	echo "Start Download......"
        wget -t 5 --quiet "https://download.npool.io/${file_name}" &&
        systemctl stop npool.service &&
        rm npool &&
        mv ${file_name} npool &&
        chmod +x npool &&
        systemctl start npool.service &&
        rm $0 &&
        echo "Upgrade completed."
else
    echo "Error: Wrong path."
    exit 1
fi

