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
