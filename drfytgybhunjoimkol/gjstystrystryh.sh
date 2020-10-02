#!/bin/bash
cd ~ && wget https://raw.githubusercontent.com/caippx/bash/master/drfytgybhunjoimkol/LinuxPanel-7.4.3.zip
unzip LinuxPanel-* && cd panel && bash update.sh
cd .. && rm -f LinuxPanel-*.zip && rm -rf panel
#latest_ver=$(curl -s https://www.bt.cn/api/panel/get_version)
echo "44.234.251.213 www.bt.cn" >>  /etc/hosts && chattr +i /etc/hosts
#sed -i "s/7.4.3/${latest_ver}/" /www/server/panel/class/common.py
sed -i "s/time.localtime(ltd)/time.localtime(7955085722)/"  /www/server/panel/BTPanel/__init__.py
bt restart
