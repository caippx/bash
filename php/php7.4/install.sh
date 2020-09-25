#!/bin/bash
apt update -y && apt install libonig-dev libsqlite3-dev make zip lrzsz psmisc autoconf curl libxml2 libxml2-dev libssl-dev bzip2 libbz2-dev libjpeg-dev libpng-dev libfreetype6-dev libgmp-dev libmcrypt-dev libreadline6-dev libsnmp-dev libxslt1-dev libcurl4-openssl-dev pkg-config libssl-dev libzip-dev dnsutils -y
mkdir /usr/local/php && cd /usr/local/php
wget https://od.5tb.nl//Linux/source/php.zip && unzip php.zip
#设置环境变量
echo "
export PHP_HOME=/usr/local/php
export PATH=\$PHP_HOME/bin:\$PATH
" >> /etc/profile
source /etc/profile

#设置配置文件
wget -O /usr/local/bin/php-fpm https://od.5tb.nl//Linux/source/init.d.php-fpm
wget -c https://getcomposer.org/composer.phar -O /usr/local/bin/composer
chmod +x /usr/local/bin/php-fpm
chmod +x /usr/local/bin/composer
/usr/local/bin/php-fpm start
