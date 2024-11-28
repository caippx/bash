function download(){
  # 随机生成一个 1G 到 5G 之间的字节数
  min=1073741824   # 1G in bytes
  max=5368709120   # 5G in bytes
  
  # 生成随机字节数
  random_bytes=$((RANDOM * (max-min+1) / 32768 + min))
  
  # 下载文件
  url="https://speed.cloudflare.com/__down?bytes=$random_bytes"
  echo "Downloading $random_bytes bytes from $url"
  curl -o /dev/null $url
}

function diskio(){
  # 随机生成一个 2G 到 8G 之间的字节数
  min=$((2 * 1024 * 1024 * 1024))  # 2G in bytes
  max=$((8 * 1024 * 1024 * 1024))  # 8G in bytes
  
  # 生成随机字节数
  random_bytes=$((RANDOM * (max-min+1) / 32768 + min))
  
  # 定义临时文件
  temp_file="random_data.bin"
  
  # 写入随机数据
  echo "Writing $random_bytes bytes to $temp_file"
  dd if=/dev/urandom of=$temp_file bs=1M count=$((random_bytes / 1024 / 1024)) status=progress
  
  # 读取随机数据
  echo "Reading from $temp_file"
  dd if=$temp_file of=/dev/null bs=1M status=progress
  
  # 删除临时文件
  rm $temp_file
}

tasks=(
    download          # 网络请求
    diskio  # 硬盘读写
)

random_index=$((RANDOM % ${#tasks[@]}))
selected_task=${tasks[$random_index]}

# 执行选定的任务
echo "Running task: $selected_task"
eval $selected_task

