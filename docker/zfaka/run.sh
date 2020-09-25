#!/bin/bash

#删除zip
rm -rf /data/wwwroot/zfaka/fk.zip
#修改数据库信息
sed -i "s/Mysql_Host/$HOST/g" /data/wwwroot/zfaka/conf/application.ini
sed -i "s/Mysql_Port/$PORT/g" /data/wwwroot/zfaka/conf/application.ini
sed -i "s/Mysql_User/$USER/g" /data/wwwroot/zfaka/conf/application.ini
sed -i "s/Mysql_Passwd/$PASSWD/g" /data/wwwroot/zfaka/conf/application.ini
sed -i "s/Mysql_DataBase/$DATABASE/g" /data/wwwroot/zfaka/conf/application.ini

#配置虚拟主机信息
echo "
server {
    listen       80;
    server_name  $DOMAIN;
    root /data/wwwroot/zfaka/public;
    location ~ \.php$ {
            fastcgi_pass   unix:/usr/local/php/var/run/www-php-fpm.sock;
            fastcgi_param  SCRIPT_FILENAME  \$document_root\$fastcgi_script_name;
            include        fastcgi_params;
    }
}
" > /etc/nginx/conf.d/zfaka.conf
certbot --nginx --agree-tos --register-unsafely-without-email --no-eff-email --email example@$DOMAIN <<EOF


EOF
