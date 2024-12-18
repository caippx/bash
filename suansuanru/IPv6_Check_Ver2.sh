#!/bin/bash

ping_ipv6() {
    local src_ip=$1
    local target_ipv6=$2
    local temp_file=$3
    local ping_output=$(ping6 -I $src_ip -i 0.3 -c 30 $target_ipv6 2>&1)
    ip addr del $src_ip/64 dev $interface_name
    local loss=$(echo "$ping_output" | grep 'packets transmitted' | awk '{print $6}')
    if [ "$loss" == "100%" ]; then
        return
    fi
    local min=$(echo "$ping_output" | grep 'rtt min/avg/max/mdev' | cut -d'=' -f2 | awk -F'/' '{print $2}')
    echo "$src_ip $min" >> "$temp_file"
}

cleanup() {
    for src_ip in "${ip_array[@]}"; do
        sudo ip addr del "$src_ip"/64 dev $interface_name 2>/dev/null
    done
    [ -f "$temp_file" ] && rm "$temp_file"
    [ -f "$temp_progress_file" ] && rm "$temp_progress_file"
}

print_progress_bar() {
    local -i current=$1
    local -i total=$2
    local filled=$((current*60/total))
    local bars=$(printf "%-${filled}s" "|" | tr ' ' '|')
    local spaces=$(printf "%-$((60-filled))s" " ")
    local percent=$((current*100/total))
    echo -ne "[${bars}${spaces}] ${percent}% ($current/$total)\r"
}
start_time=$(date +%s)
trap cleanup EXIT
interface_name=$(ip -6  route | grep default | grep -Po '(?<=dev )(\S+)' | head -1)
current_ipv6=$(ip -6 addr show $interface_name | grep 'inet6' | grep -v 'fe80' | awk '{print $2}' | cut -d'/' -f1 | head -n 1)
current_prefix=$(echo $current_ipv6 | cut -d':' -f1-4)
echo ""
echo "网卡当前配置的IPv6： $current_ipv6"
echo "分配该虚拟机的IPv6： $current_prefix::/64"
echo ""
stty erase '^H' && read -p "请输入你要检测的对端IPv6: " target_ipv6
if ! [[ "$target_ipv6" =~ ^([0-9a-fA-F:]+)$ && "${#target_ipv6}" -ge 15 && "${#target_ipv6}" -le 39 ]]; then
    echo "你输入的这个地址看着不太对哇！"
    exit 1
fi
stty erase '^H' && read -p "请输入你要测试多少个IPv6（建议512M机型小于500个）: " ipv6_num
if ! [[ "$ipv6_num" =~ ^[0-9]+$ ]]; then
    echo "写的啥玩意？认真点！"
    exit 1
fi
if [ "$ipv6_num" == 0 ]; then
    echo "你看看你输的数量对吗？"
    exit 1
fi
if echo "$ipv6_num 18446744073709551615" | awk '{exit !($1>$2)}'; then
    echo "$ipv6_num个？你的小鸡要冒烟咯！"
    exit 1
fi
declare -a ip_array
echo ""
echo "在 $current_prefix::/64 中生成$ipv6_num个IPv6进行检测 请等待任务完成"

declare -a ipv6_array=()
declare -A used_ip_addrs 
used_ip_addrs[$current_ipv6]=1
current_count=0
for (( i=0; i<$ipv6_num; i++ )); do
    while : ; do
        random_part=$(printf '%x:%x:%x:%x' $((RANDOM%65536)) $((RANDOM%65536)) $((RANDOM%65536)) $((RANDOM%65536)))
        test_ipv6="$current_prefix:$random_part"
        if [ -z ${used_ip_addrs[$test_ipv6]} ]; then
            sudo ip addr add "$test_ipv6"/64 dev $interface_name 2>/dev/null
         	  used_ip_addrs[$test_ipv6]=1
            ip_array+=($test_ipv6)
            ((current_count++))
   		  print_progress_bar $current_count $ipv6_num
            break
         else
           echo "IPv6地址 $test_ipv6 已存在，正在重新生成..."
        fi
    done
done


sleep 5s 
temp_file=$(mktemp)
declare -A ipv6_rtt_results

# 动态并发
total_jobs=${#ip_array[@]}
quarter_jobs=$((total_jobs / 4))
if [ "$quarter_jobs" -gt 200 ]; then
    parallel_jobs=200
else
    parallel_jobs=$quarter_jobs
fi
completed_jobs=0
temp_progress_file=$(mktemp)
echo
echo "对$total_jobs个IPv6进行Ping测试中 请等待任务完成"
print_progress_bar $completed_jobs $total_jobs
{
    for src_ip in "${ip_array[@]}"; do
        (
            ping_ipv6 "$src_ip" "$target_ipv6" "$temp_file" 
            sudo ip addr del "$src_ip"/64 dev $interface_name 2>/dev/null
            echo >> "$temp_progress_file"
        ) &
        if (( $(jobs | wc -l) >= parallel_jobs )); then
            wait -n
            completed_jobs=$(wc -l < "$temp_progress_file")
            percent=$((completed_jobs * 100 / total_jobs))
            print_progress_bar $completed_jobs $total_jobs
        fi
    done
    wait
}
while [ "$(wc -l < "$temp_progress_file")" -lt "$total_jobs" ]; do
    sleep 1
    completed_jobs=$(wc -l < "$temp_progress_file")
    print_progress_bar $completed_jobs $total_jobs
done
completed_jobs=$(wc -l < "$temp_progress_file")
print_progress_bar $completed_jobs $total_jobs
wait
echo ""
echo "====================================================="
echo "IPv6                                     Average"
sort -k2 -n "$temp_file" | head -n 10 | while read -r line; do
    ipv6=$(echo "$line" | awk '{print $1}')
    rtt=$(echo "$line" | awk '{print $2}')
    printf "%-40s %s ms\n" "$ipv6" "$rtt"
done
echo "====================================================="
end_time=$(date +%s)
elapsed_time=$((end_time - start_time))
echo "脚本总耗时: $elapsed_time 秒。"
echo "Power by PoloCloud@Wang_Boluo Mod by @KorenKrita" #给个面子别删吧哥
