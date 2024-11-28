# 生成随机小时和分钟
hour=$((RANDOM % 24))
minute=$((RANDOM % 60))

# 格式化时间为 HH:MM
random_time=$(printf "%02d:%02d" $hour $minute)

# 使用 `at` 命令计划在随机时间运行你的脚本
echo "/root/vrsc/random_usage.sh" | at $random_time
