#!/bin/bash

#设置环境变量
echo "
export PHP_HOME=/usr/local/php
export PATH=\$PHP_HOME/bin:\$PATH
" >> /etc/profile
source /etc/profile

#移动配置文件和启动文件

chmod +x /usr/local/bin/php-fpm
chmod +x /usr/local/bin/composer
