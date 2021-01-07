
Happy_Bt(){
echo "44.234.251.213 www.bt.cn" >>  /etc/hosts && chattr +i /etc/hosts
sed -i "s/time.localtime(ltd)/time.localtime(7955085722)/"  /www/server/panel/BTPanel/__init__.py
curl -s -o /dev/null www.bt.cn
wget -qO /www/server/panel/data/plugin.json http://www.bt.cn/api/panel/get_soft_list_test
echo "True" > /www/server/panel/data/licenes.pl
}

Change_Path(){
echo "\/$1" > /www/server/panel/data/admin_path.pl
}

Change_Admin(){
bt << EOF
6
$2
EOF
}

Change_Passwd(){
bt << EOF
5
$3
EOF
}

curl -sSO http://download.bt.cn/install/install_panel.sh && bash install_panel.sh
Happy_Bt
[[ -n $1 ]] && Change_Path
[[ -n $2 ]] && Change_Admin
[[ -n $3 ]] && Change_Passwd
