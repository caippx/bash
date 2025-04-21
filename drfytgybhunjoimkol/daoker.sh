#!/bin/bash

if command -v docker >/dev/null 2>&1; then
    echo "docker 已安装"
else
    apt update -y && bash <(curl -sSL https://get.docker.com)
fi

TOKEN=$1
t=$2

docker run -d --restart always --name nginx traffmonetizer/cli_v2 start accept --token $TOKEN
docker exec nginx sh -c "
for i in \$(seq 1 $t); do
  dir=/tr/\$i
  mkdir -p \$dir
  cd \$dir
  /app/Cli start accept --token $TOKEN >/dev/null 2>&1 &
  sleep 0.5
done
"
