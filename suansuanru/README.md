适用于debian9+

一键搭建ssr+tls+web伪装 ssr443端口 https8443端口

建议使用rdns作为伪装域名

bash <(wget --no-check-certificate -qO- 'https://raw.githubusercontent.com/caippx/bash/master/suansuanru/ssrtls.sh')


适用于debian9+ Ubuntu16+ centos7+ 


一键V2ray+Caddy http 适用于CDN caddy端口80 v2ray端口 8848


bash <(wget --no-check-certificate -qO- 'https://raw.githubusercontent.com/caippx/bash/master/suansuanru/v2ray-ws-http.sh')

#GOST<br>
wget https://github.com/ginuerzh/gost/releases/download/v2.11.1/gost-linux-amd64-2.11.1.gz && gunzip gost-linux-amd64-2.11.1.gz<br>
mv gost-linux-amd64-2.11.1 /usr/bin/gost && chmod +x /usr/bin/gost<br>
gost -L=rtcp://:8848/remote_ip:8080 <br>
nohup gost -L=tcp://:80/1.0.0.1:80 >>/dev/null 2>&1 & <br>
nohup gost -L=tcp://:443/1.0.0.1:443 >>/dev/null 2>&1 & <br>
nohup gost -L=udp://:443/1.0.0.1:443 >>/dev/null 2>&1 &
