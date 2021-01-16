
Happy_Bt(){
echo "44.234.251.213 www.bt.cn" >>  /etc/hosts && chattr +i /etc/hosts
sed -i "s/time.localtime(ltd)/time.localtime(7955085722)/"  /www/server/panel/BTPanel/__init__.py
curl -s -o /dev/null www.bt.cn
wget -qO /www/server/panel/data/plugin.json http://www.bt.cn/api/panel/get_soft_list_test
echo "True" > /www/server/panel/data/licenes.pl
}

Is_Set_(){
read -p "设置面板后台入口（留空或者n随机 默认随机）" admin_path
read -p "设置后台账户（留空或者n随机 默认随机） >3位" admin_
read -p "设置后台密码（留空或者n随机 默认随机）>5位" admin_pwd
}

Change_Path(){
echo "/$1" > /www/server/panel/data/admin_path.pl
}

Change_Admin(){
bt << EOF
6
$1
EOF
}

Change_Passwd(){
bt << EOF
5
$1
EOF
}
ip=`curl -s http://whatismyip.akamai.com/`
curl -sSO http://download.bt.cn/install/install_panel.sh && bash install_panel.sh
Happy_Bt
echo "开始安装IP SSL插件"
wget --no-check-certificate -qO /www/server/panel/plugin/encryption365.zip https://ppxbot2.ppxproject.workers.dev/0:/%E8%BD%AF%E4%BB%B6/Linux/bt/encryption365.zip && cd /www/server/panel/plugin/ && unzip encryption365.zip >/dev/null 2>&1
echo "done"
[[ -n $1 ]] && echo  "外网面板地址: http://$ip:8888/$1" && Change_Path $1 >/dev/null 2>&1
[[ -n $2 ]] && echo  "新用户名: $1" && Change_Admin $2 >/dev/null 2>&1
[[ -n $3 ]] && echo  "新密码: $1" && Change_Passwd $3 >/dev/null 2>&1
bt restart
iptables -I INPUT -p tcp -m state --state NEW -m tcp --dport 443 -j ACCEPT
iptables -I INPUT -p udp -m state --state NEW -m udp --dport 443 -j ACCEPT

