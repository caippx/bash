#!/bin/bash

apt install wget curl zip unzip lrzsz psmisc -y
groupadd -r www
useradd -r -g www -s /bin/false -d /usr/local/www -M www
nginx_install_dir='/etc/nginx/'
mkdir $nginx_install_dir
cd $nginx_install_dir && wget https://github.com/caippx/bash/raw/master/nginx/nginx.zip && unzip nginx.zip
[ -z "`grep ^'export PATH=' /etc/profile`" ] && echo "export PATH=${nginx_install_dir}/sbin:\$PATH" >> /etc/profile
[ -n "`grep ^'export PATH=' /etc/profile`" -a -z "`grep ${nginx_install_dir} /etc/profile`" ] && sed -i "s@^export PATH=\(.*\)@export PATH=${nginx_install_dir}/sbin:\1@" /etc/profile
. /etc/profile
wget -P /lib/systemd/system/ https://raw.githubusercontent.com/caippx/bash/master/nginx/nginx.service
sed -i "s@/usr/local/nginx@${nginx_install_dir}@g" /lib/systemd/system/nginx.service
systemctl enable nginx
mv ${nginx_install_dir}/conf/nginx.conf{,_bk}
wget -P ${nginx_install_dir}/conf https://raw.githubusercontent.com/caippx/bash/master/nginx/nginx.conf
mkdir -p ${nginx_install_dir}/conf/vhost
