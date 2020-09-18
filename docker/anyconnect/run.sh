#!/bin/bash

domain=$DOMAIN
pwd=$PWD

sed -i "s/server.cert.pem/crt.crt/" /etc/ocserv/ocserv.conf
sed -i "s/server.key.pem/key.key/" /etc/ocserv/ocserv.conf
sed -i "s/#udp-port = 443/udp-port = 443/" /etc/ocserv/ocserv.conf

openssl genrsa -out /etc/ocserv/key.key 2048
openssl req -new -x509 -days 3650 -key /etc/ocserv/key.key -out /etc/ocserv/crt.crt -subj -subj "/C=HH/ST=HANHAN/L=HH/O=hanhanvpn/OU=hanhanvpn/CN=${domain}"

ocpasswd -g NoRoute ppxnoroute <<EOF
$pwd
$pwd
EOF


ocpasswd -g Route ppxroute <<EOF
$pwd
$pwd
EOF


ocpasswd -g Default ppx <<EOF
$pwd
$pwd
EOF
