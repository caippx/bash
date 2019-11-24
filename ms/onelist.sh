#!/bin/bash

apt update -y
apt install python3 python3-pip git -y
pip3 install tornado
git clone https://github.com/MoeClub/OneList.git && cd OneList
echo "
请打开
https://login.microsoftonline.com/common/oauth2/v2.0/authorize?client_id=0b9e8402-43bd-4c14-84a4-2f00cc9f4861&response_type=code&redirect_uri=http://localhost/onedrive-login&response_mode=query&scope=offline_access%20User.Read%20Files.ReadWrite.All
获取code"
echo && stty erase '^H' && read -p "输入code: " code
python3 OneList.py << EOF
$code
EOF
python3 app.py &
