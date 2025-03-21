#!/bin/bash

sudo curl -L "https://github.com/docker/compose/releases/download/v2.34.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
#国内
#curl -L https://get.daocloud.io/docker/compose/releases/download/v2.34.0/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose 

chmod +x /usr/local/bin/docker-compose
ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
docker-compose version
