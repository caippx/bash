#!/bin/bash


filepath=$(cd "$(dirname "$0")"; pwd)
file=$(echo -e "${filepath}"|awk -F "$0" '{print $1}')
ssr_folder="/usr/local/shadowsocksr"
ssr_ss_file="${ssr_folder}/shadowsocks"
config_file="${ssr_folder}/config.json"
config_folder="/etc/shadowsocksr"
config_user_file="${config_folder}/user-config.json"
ssr_log_file="${ssr_ss_file}/ssserver.log"
Libsodiumr_file="/usr/local/lib/libsodium.so"
jq_file="${ssr_folder}/jq"
Green_font_prefix="\033[32m" && Red_font_prefix="\033[31m" && Green_background_prefix="\033[42;37m" && Red_background_prefix="\033[41;37m" && Font_color_suffix="\033[0m"
Info="${Green_font_prefix}[信息]${Font_color_suffix}"
Error="${Red_font_prefix}[错误]${Font_color_suffix}"
Tip="${Green_font_prefix}[注意]${Font_color_suffix}"
Separator_1="——————————————————————————————"


Add_iptables(){
	iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport 8443 -j ACCEPT
	iptables -I INPUT -m state --state NEW -m udp -p udp --dport 8443 -j ACCEPT
	ip6tables -I INPUT -m state --state NEW -m tcp -p tcp --dport 8443 -j ACCEPT
	ip6tables -I INPUT -m state --state NEW -m udp -p udp --dport 8443 -j ACCEPT
    iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport 443 -j ACCEPT
	iptables -I INPUT -m state --state NEW -m udp -p udp --dport 443 -j ACCEPT
	ip6tables -I INPUT -m state --state NEW -m tcp -p tcp --dport 443 -j ACCEPT
	ip6tables -I INPUT -m state --state NEW -m udp -p udp --dport 443 -j ACCEPT
    iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport 80 -j ACCEPT
	iptables -I INPUT -m state --state NEW -m udp -p udp --dport 80 -j ACCEPT
	ip6tables -I INPUT -m state --state NEW -m tcp -p tcp --dport 80 -j ACCEPT
	ip6tables -I INPUT -m state --state NEW -m udp -p udp --dport 80 -j ACCEPT
    iptables-save > /etc/iptables.up.rules
	ip6tables-save > /etc/ip6tables.up.rules
}

libsodium_install(){
	apt-get update
	apt-get install gcc make build-essential -y
	wget https://github.com/jedisct1/libsodium/releases/download/1.0.16/libsodium-1.0.16.tar.gz
	tar xf libsodium-1.0.16.tar.gz && cd libsodium-1.0.16
	./configure && make -j2 && make install
	ldconfig
	rm -rf libsodium-1.0.16*
	cd ..
}

urlsafe_base64(){
	date=$(echo -n "$1"|base64|sed ':a;N;s/\n/ /g;ta'|sed 's/ //g;s/=//g;s/+/-/g;s/\//_/g')
	echo -e "${date}"
}

Write_configuration(){
	cat > ${config_user_file}<<-EOF
{
    "server": "0.0.0.0",
    "server_ipv6": "::",
    "server_port": 443,
    "local_address": "127.0.0.1",
    "local_port": 1080,
    "password": "ppxwo.com",
    "method": "chacha20-ietf",
    "protocol": "auth_aes128_md5",
    "protocol_param": "",
    "obfs": "tls1.2_ticket_auth",
    "obfs_param": "$domain",
    "speed_limit_per_con": 0,
    "speed_limit_per_user": 0,
    "additional_ports" : {},
    "timeout": 120,
    "udp_timeout": 60,
    "dns_ipv6": false,
    "connect_verbose_info": 0,
    "redirect": ["*:443#127.0.0.1:8443"],
    "fast_open": false
}
EOF
}

Install_SSR(){
    cd "/usr/local"
    wget -N --no-check-certificate "https://github.com/caippx/shadowsocksr/archive/manyuser.zip"
    [[ ! -e "manyuser.zip" ]] && echo -e "${Error} ShadowsocksR服务端 压缩包 下载失败 !" && rm -rf manyuser.zip && exit 1
    unzip "manyuser.zip"
    [[ ! -e "/usr/local/shadowsocksr-manyuser/" ]] && echo -e "${Error} ShadowsocksR服务端 解压失败 !" && rm -rf manyuser.zip && exit 1
    mv "/usr/local/shadowsocksr-manyuser/" "/usr/local/shadowsocksr/"
    [[ ! -e "/usr/local/shadowsocksr/" ]] && echo -e "${Error} ShadowsocksR服务端 重命名失败 !" && rm -rf manyuser.zip && rm -rf "/usr/local/shadowsocksr-manyuser/" && exit 1
    rm -rf manyuser.zip
    [[ -e ${config_folder} ]] && rm -rf ${config_folder}
	mkdir ${config_folder}
    [[ ! -e ${config_folder} ]] && echo -e "${Error} ShadowsocksR配置文件的文件夹 建立失败 !" && exit 1
	echo -e "${Info} ShadowsocksR服务端 下载完成 !"
    if ! wget --no-check-certificate https://raw.githubusercontent.com/ToyoDAdoubi/doubi/master/service/ssr_debian -O /etc/init.d/ssr; then
		echo -e "${Error} ShadowsocksR服务 管理脚本下载失败                                                                                                                                                                                                                                                                                                                                                                                                                !" && exit 1
	fi
		chmod +x /etc/init.d/ssr
		update-rc.d -f ssr defaults
	echo -e "${Info} ShadowsocksR服务 管理脚本下载完成 !"
    echo -e "${Info} 开始写入 ShadowsocksR配置文件..."
    Write_configuration
    /etc/init.d/ssr start
}
ssr_link_qr(){
	SSRprotocol=$(echo ${protocol} | sed 's/_compatible//g')
	SSRobfs=$(echo ${obfs} | sed 's/_compatible//g')
	SSRPWDbase64=$(urlsafe_base64 "${password}")
	SSRobfsparam=$(urlsafe_base64 "${domain}")
	SSRbase64=$(urlsafe_base64 "${ip}:${port}:${SSRprotocol}:${method}:${SSRobfs}:${SSRPWDbase64}/?obfsparam=${SSRobfsparam}")
	SSRurl="ssr://${SSRbase64}"
	SSRQRcode="https://api.qrserver.com/v1/create-qr-code/?size=150x150&data=${SSRurl}"
	ssr_link=" SSR   链接 : ${Red_font_prefix}${SSRurl}${Font_color_suffix} \n SSR 二维码 : ${Red_font_prefix}${SSRQRcode}${Font_color_suffix} \n "
}
ss_ssr_determine(){
	protocol_suffix=`echo ${protocol} | awk -F "_" '{print $NF}'`
	obfs_suffix=`echo ${obfs} | awk -F "_" '{print $NF}'`
	if [[ ${protocol} = "origin" ]]; then
		if [[ ${obfs} = "plain" ]]; then
			ss_link_qr
			ssr_link=""
		else
			if [[ ${obfs_suffix} != "compatible" ]]; then
				ss_link=""
			else
				ss_link_qr
			fi
		fi
	else
		if [[ ${protocol_suffix} != "compatible" ]]; then
			ss_link=""
		else
			if [[ ${obfs_suffix} != "compatible" ]]; then
				if [[ ${obfs_suffix} = "plain" ]]; then
					ss_link_qr
				else
					ss_link=""
				fi
			else
				ss_link_qr
			fi
		fi
	fi
	ssr_link_qr
}
Get_User(){
	[[ ! -e ${jq_file} ]] && echo -e "${Error} JQ解析器 不存在，请检查 !" && exit 1
	port=`${jq_file} '.server_port' ${config_user_file}`
	password=`${jq_file} '.password' ${config_user_file} | sed 's/^.//;s/.$//'`
	method=`${jq_file} '.method' ${config_user_file} | sed 's/^.//;s/.$//'`
	protocol=`${jq_file} '.protocol' ${config_user_file} | sed 's/^.//;s/.$//'`
	obfs=`${jq_file} '.obfs' ${config_user_file} | sed 's/^.//;s/.$//'`
	protocol_param=`${jq_file} '.protocol_param' ${config_user_file} | sed 's/^.//;s/.$//'`
	speed_limit_per_con=`${jq_file} '.speed_limit_per_con' ${config_user_file}`
	speed_limit_per_user=`${jq_file} '.speed_limit_per_user' ${config_user_file}`
	connect_verbose_info=`${jq_file} '.connect_verbose_info' ${config_user_file}`
}

View_User(){
	ip=$domain
	Get_User
	[[ -z ${protocol_param} ]] && protocol_param="0(无限)"
		ss_ssr_determine
		clear && echo "===================================================" && echo
		echo -e " ShadowsocksR账号 配置信息：" && echo
		echo -e " I  P\t    : ${Green_font_prefix}${ip}${Font_color_suffix}"
		echo -e " 端口\t    : ${Green_font_prefix}${port}${Font_color_suffix}"
		echo -e " 密码\t    : ${Green_font_prefix}${password}${Font_color_suffix}"
		echo -e " 加密\t    : ${Green_font_prefix}${method}${Font_color_suffix}"
		echo -e " 协议\t    : ${Red_font_prefix}${protocol}${Font_color_suffix}"
		echo -e " 混淆\t    : ${Red_font_prefix}${obfs}${Font_color_suffix}"
		echo -e " 设备数限制 : ${Green_font_prefix}${protocol_param}${Font_color_suffix}"
		echo -e " 单线程限速 : ${Green_font_prefix}${speed_limit_per_con} KB/S${Font_color_suffix}"
		echo -e " 端口总限速 : ${Green_font_prefix}${speed_limit_per_user} KB/S${Font_color_suffix}"
		echo -e "${ss_link}"
		echo -e "${ssr_link}"
		echo -e " ${Green_font_prefix} 提示: ${Font_color_suffix}
 在浏览器中，打开二维码链接，就可以看到二维码图片。
 协议和混淆后面的[ _compatible ]，指的是 兼容原版协议/混淆。"
		echo && echo "==================================================="
	
}

Install_Caddy(){
wget -O /usr/bin/caddy https://raw.githubusercontent.com/caippx/caddy-v1/master/caddy
chmod +x /usr/bin/caddy
ulimit -n 51200
mkdir -p /data/www/default
mkdir -p /etc/caddy/conf.d
echo "import conf.d/*" > /etc/caddy/caddy.conf
echo "
https://$domain:8443 {
root /data/www/$domain
tls admin@$domain
gzip
}
http://$domain {
root /data/www/$domain
gzip
}
" > /etc/caddy/conf.d/$domain
mkdir -p /data/www/$domain
echo $txt > /data/www/$domain/index.html
killall -9 caddy
ulimit -n 51200
nohup caddy -conf=/etc/caddy/caddy.conf -agree -quic >> /tmp/caddy.log 2>&1 &
}

apt update -y
apt install lrzsz python zip git cron net-tools curl psmisc -y
echo && stty erase '^H' && read -p "输入域名(提前绑定到VPS IP): " domain
echo && stty erase '^H' && read -p "网页内容: " txt
Install_Caddy
cp -f /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
/etc/init.d/cron restart
libsodium_install
Install_SSR
wget --no-check-certificate "https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64" -O ${jq_file}
chmod +x ${jq_file}
echo -e "${Info} JQ解析器 安装完成，继续..." 
View_User
