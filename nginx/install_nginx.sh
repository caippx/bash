#!/bin/bash

nginx_install_dir="/etc/nginx"
apt-get install libpcre3-dev libaio1 libjemalloc-dev -y
apt-get install -y gcc g++ make zip lrzsz psmisc autoconf curl libxml2 libxml2-dev libssl-dev bzip2 libbz2-dev libjpeg-dev libpng-dev libfreetype6-dev libgmp-dev libmcrypt-dev libreadline6-dev libsnmp-dev libxslt1-dev libcurl4-openssl-dev pkg-config libssl-dev libzip-dev dnsutils
groupadd -r www
useradd -r -g www -s /bin/false -d /usr/local/www -M www
wget http://nginx.org/download/nginx-1.19.2.tar.gz && tar -zxf nginx-1.19.2.tar.gz && cd nginx-1.19.2
echo && stty erase '^H' && read -p "输入要修改的名字：" name
sed -i "s#\"NGINX\"#\"$name\"#" src/core/nginx.h
sed -i "s#\"nginx/\"#\"$name/\"#" src/core/nginx.h
sed -i "s#Server: nginx#Server: $name#" src/http/ngx_http_header_filter_module.c
sed -i "s#\"<hr><center>nginx<\/center>\"#\"<hr><center>$name<\/center>\"#" src/http/ngx_http_special_response.c
sed -i "s#server: nginx#server: $name#" src/http/v2/ngx_http_v2_filter_module.c
mkdir -p ${nginx_install_dir} && mkdir -p /data/wwwlogs/ && mkdir -p /data/wwwroot/default
wget https://www.openssl.org/source/openssl-1.1.1d.tar.gz && tar -zxf openssl-1.1.1d.tar.gz
./configure --prefix=${nginx_install_dir} --user=www --group=www \
--with-http_stub_status_module --with-http_v2_module --with-http_ssl_module --with-http_gzip_static_module \
--with-http_realip_module --with-http_flv_module --with-http_mp4_module \
--with-openssl=./openssl-1.1.1d --with-pcre --with-pcre-jit --with-ld-opt='-ljemalloc' --with-http_sub_module
make && make install
cd ~ && rm -rf nginx-1.19.2.tar.gz nginx-1.19.2
[ -z "`grep ^'export PATH=' /etc/profile`" ] && echo "export PATH=${nginx_install_dir}/sbin:\$PATH" >> /etc/profile
[ -n "`grep ^'export PATH=' /etc/profile`" -a -z "`grep ${nginx_install_dir} /etc/profile`" ] && sed -i "s@^export PATH=\(.*\)@export PATH=${nginx_install_dir}/sbin:\1@" /etc/profile
. /etc/profile
wget -P /lib/systemd/system/ https://raw.githubusercontent.com/caippx/bash/master/nginx/nginx.service
sed -i "s@/usr/local/nginx@${nginx_install_dir}@g" /lib/systemd/system/nginx.service
systemctl enable nginx
mv ${nginx_install_dir}/conf/nginx.conf{,_bk}
wget -P ${nginx_install_dir}/conf https://raw.githubusercontent.com/caippx/bash/master/nginx/nginx.conf
mkdir -p ${nginx_install_dir}/conf/vhost
