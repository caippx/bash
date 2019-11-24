#!/bin/bash

apt update -y
apt install python3 python3-pip -y
pip3 install tornado
echo "
请打开
https://login.microsoftonline.com/common/oauth2/v2.0/authorize?client_id=ea2b36f6-b8ad-40be-bc0f-e5e4a4a7d4fa&response_type=code&redirect_uri=http://localhost/onedrive-login&response_mode=query&scope=offline_access%20User.Read%20Files.ReadWrite.All
获取code"
echo && stty erase '^H' && read -p "输入code: " code
python3 OneList.py << EOF
$code
EOF
python3 app.py &
