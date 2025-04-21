#!/bin/bash

bash <(curl -sSL https://get.docker.com)
TOKEN=$1

docker run -d --restart always --name nginx traffmonetizer/cli_v2 start accept --token $TOKEN
docker exec nginx sh -c "
for i in \$(seq 1 20); do
  dir=/tr/\$i
  mkdir -p \$dir
  cd \$dir
  /app/Cli start accept --token $TOKEN >/dev/null 2>&1 &
done
"
