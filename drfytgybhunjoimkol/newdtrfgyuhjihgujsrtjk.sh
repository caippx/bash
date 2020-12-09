
Happy_Bt(){
echo "44.234.251.213 www.bt.cn" >>  /etc/hosts && chattr +i /etc/hosts
sed -i "s/time.localtime(ltd)/time.localtime(7955085722)/"  /www/server/panel/BTPanel/__init__.py
curl -s -o /dev/null www.bt.cn
wget -O /www/server/panel/data/plugin.json http://www.bt.cn/api/panel/get_soft_list_test
}

curl -sSO http://download.bt.cn/install/install_panel.sh && bash install_panel.sh
Happy_Bt
