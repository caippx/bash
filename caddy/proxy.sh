#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

Caddy_Install(){
apt update -y
apt install curl zip lrzsz psmisc dnsutils -y
groupadd -r www
useradd -r -g www -s /bin/false -d /usr/local/www -M www
echo "正在安装Caddy..."
wget -O /usr/bin/caddy https://raw.githubusercontent.com/caippx/caddy-v1/master/caddy
chmod +x /usr/bin/caddy
ulimit -n 51200
mkdir -p /data/www/
mkdir -p /etc/caddy/conf.d
echo "import conf.d/*" > /etc/caddy/caddy.conf
chown -R www:www /data/www/
echo '
stop(){
killall -9 caddy
}
start(){
ulimit -n 51200
nohup caddy -conf=/etc/caddy/caddy.conf -agree -quic >> /tmp/caddy.log 2>&1 &
sleep 10
runcaddy=`ps -ef | grep -v grep | grep "caddy"`
[[ -n ${runcaddy} ]] && echo "Caddy 启动成功!" && echo "反代将会自动替换域名"
[[ -z ${runcaddy} ]] && echo "Caddy 启动失败,可能是配置错误"
}

restart(){
stop
start
}

status(){

runcaddy=`ps -ef | grep -v grep | grep "caddy"`
[[ -n ${runcaddy} ]] && echo "Caddy 启动成功!"
[[ -z ${runcaddy} ]] && echo "Caddy 未运行"

}

[[ $1 == "start" ]] && start
[[ $1 == "stop" ]] && stop
[[ $1 == "restart" ]] && restart
[[ $1 == "status" ]] && status
' > /usr/bin/ppxcaddy
chmod +x /usr/bin/ppxcaddy
echo "usage-ppxcaddy start/stop/restart/status"
}
Caddy_Config(){
protocol="http://"
filter_txt=""
echo && stty erase '^H' && read -p "输入域名(如要启用SSL请提前绑定到VPS IP): " domain
[[ -z ${domain} ]] && echo "域名为空" && exit 0
echo && stty erase '^H' && read -p "是否启用SSL(HTTPS):[y/n] " ssl
[[ ${ssl} == "y" ]] && sslinfo="tls xxxx@$domain" && protocol="https://"
echo "正在检查输入域名是否解析IP"
IP=`dig $domain | grep $domain | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}"`
IP_VPS=`curl http://whatismyip.akamai.com`
[[ ${IP} != ${IP_VPS} ]] && echo "解析暂未生效，请稍候重试" && exit 0
echo && stty erase '^H' && read -p "输入你要反代的域名 不带https/http 例如(www.baidu.com): " proxy_domain
echo && stty erase '^H' && read -p "输入你要替换的原内容不需要请留空(默认已经替换域名)：" filter_txt_old
[[ -n ${filter_txt_old} ]] && stty erase '^H' && read -p "输入你要替换的内容：" filter_txt_new && filter_txt="
filter rule {
    path .*
    search_pattern \"$filter_txt_old\"
    replacement \"$filter_txt_new\"
}
"

echo "
$domain {
root /data/www/$domain
$sslinfo
gzip
proxy / https://$proxy_domain        {
        header_upstream Host $proxy_domain
        header_upstream Referer https://$proxy_domain
        header_upstream -X-Forwarded-For
        header_upstream X-Real-IP {remote}
        header_upstream User-Agent {>User-Agent}
        header_upstream Accept-Encoding identity
        }

filter rule {
    path .*
    search_pattern $proxy_domain
    replacement $domain
}

$filter_txt

##filter


}
" > /etc/caddy/conf.d/$domain

mkdir -p /data/www/$domain
chown www:www -R /data/www/$domain
killall -9 caddy
ulimit -n 51200
nohup caddy -conf=/etc/caddy/caddy.conf -agree -quic >> /tmp/caddy.log 2>&1 &
sleep 10
runcaddy=`ps -ef | grep -v grep | grep "caddy"`
[[ -n ${runcaddy} ]] && echo "Caddy 启动成功!" && echo "反代将会自动替换域名"
[[ -z ${runcaddy} ]] && echo "Caddy 启动失败,可能是配置错误"
}


[ ! -f "/etc/caddy/caddy.conf" ] && Caddy_Install
[ -f "/etc/caddy/caddy.conf" ] && echo "Caddy已经安装 增加新反代配置" && Caddy_Config
