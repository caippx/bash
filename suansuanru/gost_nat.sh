#!/bin/bash
set -e

ALIAS_FILE="/etc/gost_alias_name"
BINARY_NAME="gost"
BINARY_DIR="/usr/bin"
BINARY_PATH="${BINARY_DIR}/${BINARY_NAME}"
GH_PROXY_PREFIX="https://ghproxy.11451185.xyz/"
CMD_FILE="/root/gost.cmd"
START_SCRIPT="/root/gost.sh"
SERVICE_NAME="gost"
SERVICE_FILE="/etc/systemd/system/gost.service"
PROCESS_MATCH_PATTERN="${BINARY_DIR}/${BINARY_NAME}"

sync_binary_path() {
  BINARY_PATH="${BINARY_DIR}/${BINARY_NAME}"
}

sync_runtime_names() {
  CMD_FILE="/root/${BINARY_NAME}.cmd"
  START_SCRIPT="/root/${BINARY_NAME}.sh"
  SERVICE_NAME="${BINARY_NAME}"
  SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"
  PROCESS_MATCH_PATTERN="${BINARY_PATH}"
}

load_binary_name() {
  if [[ -f "$ALIAS_FILE" ]]; then
    read -r BINARY_NAME < "$ALIAS_FILE"
    sync_binary_path
    sync_runtime_names
  fi
}

save_binary_name() {
  echo "$BINARY_NAME" > "$ALIAS_FILE"
}

prompt_input() {
  local var_name="$1"
  local prompt="$2"

  echo && stty erase '^H'
  read -r -p "$prompt" "$var_name"
}

prompt_yes_no() {
  local prompt="$1"
  local reply

  echo && stty erase '^H'
  read -r -p "$prompt" reply
  [[ "$reply" =~ ^[Yy]$ ]]
}

ask_binary_alias() {
  if prompt_yes_no "检测到当前服务器位于中国大陆或无法访问 github.com，是否将 gost 伪装为 java 进程名运行? [y/N]: "; then
    if command -v java >/dev/null 2>&1 && [[ "$(command -v java)" != "$BINARY_PATH" ]]; then
      if prompt_yes_no "系统中已存在 java 命令，覆盖后可能影响原有 Java，是否继续? [y/N]: "; then
        BINARY_NAME="java"
      else
        BINARY_NAME="gost"
      fi
    else
      BINARY_NAME="java"
    fi
  else
    BINARY_NAME="gost"
  fi

  sync_binary_path
  sync_runtime_names
  save_binary_name
}

append_command_to_gost_sh() {
  local cmd="$1"
  local file="$START_SCRIPT"

  if [[ ! -f "$file" ]]; then
    printf '#!/bin/bash\nset -e\n' > "$file"
  fi

  if tail -n 1 "$file" | grep -qx 'wait'; then
    sed -i '$d' "$file"
  fi

  printf '%s\n' "$cmd" >> "$file"
  echo "wait" >> "$file"
}

ensure_dependencies() {
  if ! command -v curl >/dev/null 2>&1 \
    || ! command -v wget >/dev/null 2>&1 \
    || ! command -v killall >/dev/null 2>&1; then
    apt update -y && apt install -y curl wget psmisc
  fi
}

proxy_github_url() {
  local url="$1"
  echo "${GH_PROXY_PREFIX}${url#https://}"
}

select_github_url() {
  if curl --connect-timeout 5 -fsS https://github.com >/dev/null 2>&1; then
    echo "能够访问 github.com，下载仍使用代理地址"
  else
    echo "无法访问 github.com，使用代理地址"
  fi >&2

  proxy_github_url "https://github.com"
}

get_public_ip() {
  local ip
  ip=$(curl --connect-timeout 5 -fsS https://api.ipify.org 2>/dev/null || true)
  if [[ -z "$ip" ]]; then
    ip=$(curl --connect-timeout 5 -fsS https://ifconfig.me/ip 2>/dev/null || true)
  fi
  echo "$ip"
}

is_china_ip() {
  local ip="$1"
  local country

  if [[ -z "$ip" ]]; then
    return 1
  fi

  country=$(curl --connect-timeout 5 -fsS "https://ipapi.co/${ip}/country/" 2>/dev/null || true)
  [[ "$country" == "CN" ]]
}

should_prompt_java_alias() {
  local ip="$1"
  local github_ok="$2"

  if is_china_ip "$ip"; then
    return 0
  fi

  if [[ "$github_ok" != "1" ]]; then
    return 0
  fi

  return 1
}

maybe_ask_binary_alias() {
  local ip github_ok

  ip=$(get_public_ip)
  if curl --connect-timeout 5 -fsS https://github.com >/dev/null 2>&1; then
    github_ok="1"
  else
    github_ok="0"
  fi

  if should_prompt_java_alias "$ip" "$github_ok"; then
    ask_binary_alias
  else
    BINARY_NAME="gost"
    sync_binary_path
    sync_runtime_names
    save_binary_name
  fi
}


install_gost() {
  local arch
  local github_url
  local package

  arch=$(uname -m)
  sync_binary_path
  sync_runtime_names

  ensure_dependencies

  github_url=$(select_github_url)

  if [[ "$arch" == "arm"* || "$arch" == "aarch64" ]]; then
    echo "系统为 ARM/aarch64"
    package="gost_3.0.0_linux_arm64.tar.gz"
  else
    echo "系统为 X86_64"
    package="gost_3.0.0_linux_amd64.tar.gz"
  fi

  wget -O "$package" "${github_url}/go-gost/gost/releases/download/v3.0.0/${package}"
  tar -zxvf "$package"
  rm -rf LICENSE README.md README_en.md "$package"
  install -m 755 gost "$BINARY_PATH"

  save_binary_name
}

list_gost() {
  pgrep -af "$PROCESS_MATCH_PATTERN" || true
}

start_gost_process() {
  local log_cmd="$1"
  shift

  nohup "$BINARY_PATH" "$@" >>/dev/null 2>&1 &
  local pid=$!
  sleep 2

  if ps -p "$pid" >/dev/null 2>&1; then
    echo "启动成功！进程ID：$pid"
  else
    echo "启动失败，请检查配置。"
    return 1
  fi

  echo "nohup $log_cmd >>/dev/null 2>&1 &" >> "$CMD_FILE"
  append_command_to_gost_sh "$log_cmd &"
}

run_plain() {
  local proxy_ip proxy_port local_port
  prompt_input proxy_ip "输入远程IP（域名）: "
  prompt_input proxy_port "输入远程端口: "
  prompt_input local_port "输入本地端口: "

  local log_cmd="$BINARY_PATH -L tcp://:$local_port/$proxy_ip:$proxy_port -L udp://:$local_port/$proxy_ip:$proxy_port"
  start_gost_process "$log_cmd" \
    -L "tcp://:$local_port/$proxy_ip:$proxy_port" \
    -L "udp://:$local_port/$proxy_ip:$proxy_port"
}

run_ws_zz() {
  local proxy_ip proxy_port local_port
  prompt_input proxy_ip "输入落地域名: "
  prompt_input proxy_port "输入落地端口: "
  prompt_input local_port "输入本地端口: "

  local log_cmd="$BINARY_PATH -L udp://:$local_port -L tcp://:$local_port -F relay+ws://$proxy_ip:$proxy_port"
  start_gost_process "$log_cmd" \
    -L "udp://:$local_port" \
    -L "tcp://:$local_port" \
    -F "relay+ws://$proxy_ip:$proxy_port"
}

run_ws_luodi() {
  local proxy_ip proxy_port local_port
  prompt_input proxy_ip "输入远程IP（域名）: "
  prompt_input proxy_port "输入远程端口: "
  prompt_input local_port "输入本地端口: "

  local log_cmd="$BINARY_PATH -L \"relay+ws://:$local_port/$proxy_ip:$proxy_port\""
  start_gost_process "$log_cmd" -L "relay+ws://:$local_port/$proxy_ip:$proxy_port"
}

run_wss_zz() {
  local proxy_ip proxy_port local_port
  prompt_input proxy_ip "输入落地域名: "
  prompt_input proxy_port "输入落地端口: "
  prompt_input local_port "输入本地端口: "

  local log_cmd="$BINARY_PATH -L udp://:$local_port -L tcp://:$local_port -F relay+wss://$proxy_ip:$proxy_port"
  start_gost_process "$log_cmd" \
    -L "udp://:$local_port" \
    -L "tcp://:$local_port" \
    -F "relay+wss://$proxy_ip:$proxy_port"
}

run_wss_luodi() {
  local proxy_ip proxy_port local_port
  prompt_input proxy_ip "输入远程IP（域名）: "
  prompt_input proxy_port "输入远程端口: "
  prompt_input local_port "输入本地端口: "

  if [[ ! -d "/gost_cert" ]]; then
    echo "证书不存在"
    exit 1
  fi

  local relay_url="relay+wss://:$local_port/$proxy_ip:$proxy_port?certFile=/gost_cert/cert.pem&keyFile=/gost_cert/key.pem"
  local log_cmd="$BINARY_PATH -L \"$relay_url\""
  start_gost_process "$log_cmd" -L "$relay_url"
}

set_service() {
  local file="$START_SCRIPT"

  if [[ ! -f "$file" ]]; then
    printf '#!/bin/bash\nset -e\nwait\n' > "$file"
  fi

  chmod +x "$file"

  if ! head -n 1 "$file" | grep -qx '#!/bin/bash'; then
    sed -i '1i#!/bin/bash' "$file"
  fi

  if ! sed -n '2p' "$file" | grep -qx 'set -e'; then
    sed -i '2iset -e' "$file"
  fi

  if ! tail -n 1 "$file" | grep -qx 'wait'; then
    echo "wait" >> "$file"
  fi

  cat <<EOF > "$SERVICE_FILE"
[Unit]
Description=Multi-port Gost server
After=network.target

[Service]
Type=simple
ExecStart=$START_SCRIPT
Restart=always
RestartSec=5
TimeoutStartSec=30
KillMode=process

[Install]
WantedBy=multi-user.target
EOF

  pkill -f "$PROCESS_MATCH_PATTERN" || true
  systemctl daemon-reload
  systemctl enable "$SERVICE_NAME.service"
  if systemctl is-active --quiet "$SERVICE_NAME.service"; then
    systemctl restart "$SERVICE_NAME.service"
  else
    systemctl start "$SERVICE_NAME.service"
  fi
  echo "
systemctl start $SERVICE_NAME.service      启动服务
systemctl restart $SERVICE_NAME.service    重启服务
systemctl status $SERVICE_NAME.service     服务状态
journalctl -u $SERVICE_NAME.service -f     详细日志
"
}

menu() {
  echo -e "请选择需要设置的传输类型:"
  echo -e "-----------------------------------"
  echo -e "[1] 不加密转发"
  echo -e "[2] ws 隧道中转设置"
  echo -e "[3] ws 隧道落地设置"
  echo -e "[4] wss 隧道中转设置"
  echo -e "[5] wss 隧道落地设置"
  echo -e "[6] 设置服务自启动"
  echo -e "注意: 同一条转发，中转与落地传输类型必须对应！"
  echo -e "此功能只需在中转机设置"
  echo -e "-----------------------------------"

  local choice
  read -r -p "请选择转发传输类型: " choice
  case "$choice" in
    1) run_plain ;;
    2) run_ws_zz ;;
    3) run_ws_luodi ;;
    4) run_wss_zz ;;
    5) run_wss_luodi ;;
    6) set_service ;;
    *)
      echo "输入错误"
      exit 1
      ;;
  esac
}

gogogo() {
  load_binary_name
  sync_binary_path
  sync_runtime_names

  if command -v "$BINARY_NAME" >/dev/null 2>&1; then
    menu
  else
    maybe_ask_binary_alias
    echo "先安装 Gost"
    install_gost
    menu
  fi
}

load_binary_name
sync_binary_path
sync_runtime_names

if [[ ${1:-} == "list" ]]; then
  list_gost
else
  gogogo
fi
