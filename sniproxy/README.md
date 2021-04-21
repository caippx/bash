
#2020-9-15新版

GO版 make_install 用于自定义编译

已经编译好的 支持linux amd64：

Ver1 仅支持https 可自定义错误返回地址：<br>
wget -O /usr/local/bin/sniproxy https://raw.githubusercontent.com/caippx/bash/master/sniproxy/sniproxy <br>
chmod +x /usr/local/bin/sniproxy<br>
wget -O /usr/local/config.yaml https://raw.githubusercontent.com/caippx/sniproxy/master/config.yaml<br>
nohup sniproxy -c /usr/local/config.yaml >> /tmp/sni.log 2>&1 &<br>


Ver2 支持http和https[推荐]：<br>
wget -O /usr/local/bin/sniproxy https://raw.githubusercontent.com/caippx/bash/master/sniproxy/sniproxy_s<br>
chmod +x /usr/local/bin/sniproxy<br>
nohup sniproxy >> /tmp/sni.log 2>&1 &<br>

bash <(wget --no-check-certificate -qO- 'https://raw.githubusercontent.com/caippx/bash/master/sniproxy/instsall.sh')


user daemon
pidfile /var/run/sniproxy.pid
 
listen 443 {
 proto tls
 table https_hosts
 access_log {
  filename /var/log/sniproxy/https_access.log
  priority notice
 }
}
table https_hosts {
 .* *:443
}


启动：service sniproxy start（如果运行无反应并没有启动，那么请直接使用 sniproxy 来启动试试）

停止：service sniproxy stop

重启：service sniproxy restart

查看状态：service sniproxy status

配置文件：/etc/sniproxy.conf

