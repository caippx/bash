#!/bin/bash

apt update -y
apt install python3 python3-pip git -y
pip3 install tornado
git clone https://github.com/caippx/OneList.git && cd OneList
echo "
请打开
https://login.microsoftonline.com/common/oauth2/v2.0/authorize?client_id=b51b95c2-a4b0-44de-a3c1-14f23a1d2d02&response_type=code&redirect_uri=https://api.us.ppxwo.top/onedrive&response_mode=query&scope=offline_access%20User.Read%20Files.ReadWrite.All
获取code"
echo && stty erase '^H' && read -p "输入code: " code
python3 OneList.py << EOF
$code

EOF
python3 app.py &
