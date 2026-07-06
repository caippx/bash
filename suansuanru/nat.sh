#!/usr/bin/env bash
set -Eeuo pipefail

# SSH Tunnel Forward Manager
# 原 gost_nat.sh 改造版：使用 OpenSSH 隧道转发，不再依赖 gost。
# 支持：新增本地转发(-L)、新增远程转发(-R)、列表、删除指定链路、安装/更新 systemd 自启动服务。

APP_NAME="ssh-tunnel-forward"
CONF_DIR="/etc/${APP_NAME}"
CONF_FILE="${CONF_DIR}/forwards.conf"
START_SCRIPT="/usr/local/sbin/${APP_NAME}-run.sh"
SERVICE_NAME="${APP_NAME}"
SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"
LOG_DIR="/var/log/${APP_NAME}"

mkdir -p "$CONF_DIR" "$LOG_DIR"
touch "$CONF_FILE"
chmod 600 "$CONF_FILE" || true

need_root() {
  if [[ "${EUID}" -ne 0 ]]; then
    echo "请使用 root 权限运行：sudo bash $0"
    exit 1
  fi
}

prompt_input() {
  local var_name="$1"
  local prompt="$2"
  local default="${3:-}"
  local value
  echo
  if [[ -n "$default" ]]; then
    read -r -p "$prompt [$default]: " value
    value="${value:-$default}"
  else
    read -r -p "$prompt: " value
  fi
  printf -v "$var_name" '%s' "$value"
}

prompt_yes_no() {
  local prompt="$1"
  local default="${2:-N}"
  local reply
  echo
  read -r -p "$prompt [y/N]: " reply
  reply="${reply:-$default}"
  [[ "$reply" =~ ^[Yy]$ ]]
}

ensure_dependencies() {
  if ! command -v ssh >/dev/null 2>&1; then
    echo "检测到未安装 OpenSSH Client，正在安装..."
    if command -v apt >/dev/null 2>&1; then
      apt update -y && apt install -y openssh-client
    elif command -v yum >/dev/null 2>&1; then
      yum install -y openssh-clients
    elif command -v dnf >/dev/null 2>&1; then
      dnf install -y openssh-clients
    else
      echo "无法自动安装 ssh，请先手动安装 OpenSSH Client。"
      exit 1
    fi
  fi
}

valid_port() {
  [[ "$1" =~ ^[0-9]+$ ]] && (( $1 >= 1 && $1 <= 65535 ))
}

new_id() {
  local base
  base="$(date +%Y%m%d%H%M%S)"
  local n=0 id
  while true; do
    if (( n == 0 )); then id="$base"; else id="${base}-${n}"; fi
    if ! awk -F'|' -v id="$id" '$1==id{found=1} END{exit found?0:1}' "$CONF_FILE"; then
      echo "$id"
      return
    fi
    n=$((n+1))
  done
}

escape_field() {
  # 配置文件使用 | 分隔，禁止字段包含 |，避免解析歧义。
  local v="$1"
  if [[ "$v" == *"|"* ]]; then
    echo "字段不能包含 | 字符" >&2
    return 1
  fi
  echo "$v"
}

build_ssh_extra_opts() {
  local identity_file="$1"
  local strict_host_key="$2"
  local keepalive_interval="$3"
  local keepalive_count="$4"
  local extra="-o ExitOnForwardFailure=yes -o ServerAliveInterval=${keepalive_interval} -o ServerAliveCountMax=${keepalive_count}"

  if [[ "$strict_host_key" =~ ^[Nn]$ ]]; then
    extra="$extra -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
  fi
  if [[ -n "$identity_file" ]]; then
    extra="$extra -i $identity_file"
  fi
  echo "$extra"
}

append_forward() {
  local type="$1" bind_addr="$2" local_port="$3" target_host="$4" target_port="$5" ssh_user="$6" ssh_host="$7" ssh_port="$8" extra_opts="$9"
  local id
  id="$(new_id)"
  printf '%s|%s|%s|%s|%s|%s|%s|%s|%s|%s\n' \
    "$(escape_field "$id")" \
    "$(escape_field "$type")" \
    "$(escape_field "$bind_addr")" \
    "$(escape_field "$local_port")" \
    "$(escape_field "$target_host")" \
    "$(escape_field "$target_port")" \
    "$(escape_field "$ssh_user")" \
    "$(escape_field "$ssh_host")" \
    "$(escape_field "$ssh_port")" \
    "$(escape_field "$extra_opts")" >> "$CONF_FILE"
  echo "已新增转发链路 ID：$id"
}

add_local_forward() {
  local bind_addr local_port target_host target_port ssh_user ssh_host ssh_port identity_file strict_host_key keepalive_interval keepalive_count extra_opts
  echo "\n新增本地 SSH 隧道转发：本机监听 -> 经 SSH 服务器 -> 目标地址"
  prompt_input bind_addr "本地监听地址，0.0.0.0 表示所有网卡，127.0.0.1 表示仅本机" "0.0.0.0"
  prompt_input local_port "本地监听端口"
  prompt_input target_host "目标地址/IP（从 SSH 服务器视角可访问）"
  prompt_input target_port "目标端口"
  prompt_input ssh_user "SSH 用户名" "root"
  prompt_input ssh_host "SSH 服务器地址/IP"
  prompt_input ssh_port "SSH 端口" "22"
  prompt_input identity_file "SSH 私钥路径，留空则使用默认密钥/交互认证" ""
  prompt_input strict_host_key "启用严格主机指纹校验？Y=启用，N=自动接受" "N"
  prompt_input keepalive_interval "保活间隔秒" "30"
  prompt_input keepalive_count "保活失败次数" "3"

  for p in "$local_port" "$target_port" "$ssh_port"; do
    if ! valid_port "$p"; then echo "端口不合法：$p"; exit 1; fi
  done

  extra_opts="$(build_ssh_extra_opts "$identity_file" "$strict_host_key" "$keepalive_interval" "$keepalive_count")"
  append_forward "L" "$bind_addr" "$local_port" "$target_host" "$target_port" "$ssh_user" "$ssh_host" "$ssh_port" "$extra_opts"
  restart_service_if_active
}

add_remote_forward() {
  local bind_addr remote_port target_host target_port ssh_user ssh_host ssh_port identity_file strict_host_key keepalive_interval keepalive_count extra_opts
  echo "\n新增远程 SSH 隧道转发：SSH 服务器监听 -> 回连本机/内网目标"
  prompt_input bind_addr "远程监听地址，0.0.0.0 表示 SSH 服务器所有网卡，127.0.0.1 表示仅服务器本机" "0.0.0.0"
  prompt_input remote_port "远程监听端口"
  prompt_input target_host "本机/内网目标地址（从当前机器视角可访问）" "127.0.0.1"
  prompt_input target_port "本机/内网目标端口"
  prompt_input ssh_user "SSH 用户名" "root"
  prompt_input ssh_host "SSH 服务器地址/IP"
  prompt_input ssh_port "SSH 端口" "22"
  prompt_input identity_file "SSH 私钥路径，留空则使用默认密钥/交互认证" ""
  prompt_input strict_host_key "启用严格主机指纹校验？Y=启用，N=自动接受" "N"
  prompt_input keepalive_interval "保活间隔秒" "30"
  prompt_input keepalive_count "保活失败次数" "3"

  for p in "$remote_port" "$target_port" "$ssh_port"; do
    if ! valid_port "$p"; then echo "端口不合法：$p"; exit 1; fi
  done

  extra_opts="$(build_ssh_extra_opts "$identity_file" "$strict_host_key" "$keepalive_interval" "$keepalive_count")"
  append_forward "R" "$bind_addr" "$remote_port" "$target_host" "$target_port" "$ssh_user" "$ssh_host" "$ssh_port" "$extra_opts"
  restart_service_if_active
}

list_forwards() {
  echo
  if [[ ! -s "$CONF_FILE" ]]; then
    echo "暂无转发链路。"
    return
  fi
  printf '%-18s %-4s %-22s %-25s %-24s\n' "ID" "类型" "监听" "目标" "SSH服务器"
  printf '%s\n' "-----------------------------------------------------------------------------------------------"
  awk -F'|' 'NF>=10 {
    type=($2=="L"?"本地":"远程");
    printf "%-18s %-4s %-22s %-25s %-24s\n", $1, type, $3":"$4, $5":"$6, $7"@"$8":"$9
  }' "$CONF_FILE"
}

delete_forward() {
  local id tmp
  list_forwards
  prompt_input id "请输入要删除的转发链路 ID"
  if ! awk -F'|' -v id="$id" '$1==id{found=1} END{exit found?0:1}' "$CONF_FILE"; then
    echo "未找到 ID：$id"
    exit 1
  fi
  tmp="$(mktemp)"
  awk -F'|' -v id="$id" '$1!=id' "$CONF_FILE" > "$tmp"
  cat "$tmp" > "$CONF_FILE"
  rm -f "$tmp"
  echo "已删除转发链路：$id"
  restart_service_if_active
}

clear_all_forwards() {
  if prompt_yes_no "确定要删除全部转发链路吗？" "N"; then
    : > "$CONF_FILE"
    echo "已清空全部转发链路。"
    restart_service_if_active
  fi
}

generate_start_script() {
  cat > "$START_SCRIPT" <<'EOS'
#!/usr/bin/env bash
set -Eeuo pipefail
APP_NAME="ssh-tunnel-forward"
CONF_FILE="/etc/${APP_NAME}/forwards.conf"
LOG_DIR="/var/log/${APP_NAME}"
mkdir -p "$LOG_DIR"

pids=()

start_one() {
  local id="$1" type="$2" bind_addr="$3" listen_port="$4" target_host="$5" target_port="$6" ssh_user="$7" ssh_host="$8" ssh_port="$9" extra_opts="${10:-}"
  local forward_arg log_file
  log_file="${LOG_DIR}/${id}.log"

  if [[ "$type" == "L" ]]; then
    forward_arg="${bind_addr}:${listen_port}:${target_host}:${target_port}"
    # shellcheck disable=SC2086
    ssh -N -T -p "$ssh_port" $extra_opts -L "$forward_arg" "${ssh_user}@${ssh_host}" >>"$log_file" 2>&1 &
  elif [[ "$type" == "R" ]]; then
    forward_arg="${bind_addr}:${listen_port}:${target_host}:${target_port}"
    # shellcheck disable=SC2086
    ssh -N -T -p "$ssh_port" $extra_opts -R "$forward_arg" "${ssh_user}@${ssh_host}" >>"$log_file" 2>&1 &
  else
    echo "[$id] unknown type: $type" >>"$log_file"
    return 1
  fi
  pids+=("$!")
  echo "[$id] started pid=${pids[-1]}" >>"$log_file"
}

if [[ ! -s "$CONF_FILE" ]]; then
  echo "No forwards configured. Sleeping..."
  sleep infinity
fi

while IFS='|' read -r id type bind_addr listen_port target_host target_port ssh_user ssh_host ssh_port extra_opts; do
  [[ -z "${id:-}" || "${id:0:1}" == "#" ]] && continue
  start_one "$id" "$type" "$bind_addr" "$listen_port" "$target_host" "$target_port" "$ssh_user" "$ssh_host" "$ssh_port" "$extra_opts"
done < "$CONF_FILE"

trap 'for p in "${pids[@]:-}"; do kill "$p" 2>/dev/null || true; done; wait || true; exit 0' TERM INT
wait
EOS
  chmod +x "$START_SCRIPT"
}

install_service() {
  ensure_dependencies
  generate_start_script
  cat > "$SERVICE_FILE" <<EOF
[Unit]
Description=SSH Tunnel Forward Manager
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=${START_SCRIPT}
Restart=always
RestartSec=5
TimeoutStartSec=30
KillMode=control-group

[Install]
WantedBy=multi-user.target
EOF
  systemctl daemon-reload
  systemctl enable "$SERVICE_NAME.service"
  systemctl restart "$SERVICE_NAME.service"
  echo "\n服务已安装/更新并启动：${SERVICE_NAME}.service"
  echo "常用命令："
  echo "  systemctl status ${SERVICE_NAME}.service"
  echo "  journalctl -u ${SERVICE_NAME}.service -f"
  echo "  systemctl restart ${SERVICE_NAME}.service"
}

restart_service_if_active() {
  generate_start_script
  if command -v systemctl >/dev/null 2>&1 && systemctl is-enabled "$SERVICE_NAME.service" >/dev/null 2>&1; then
    systemctl daemon-reload
    systemctl restart "$SERVICE_NAME.service"
    echo "已重启服务，使配置生效。"
  else
    echo "提示：尚未安装自启动服务，请在菜单选择“安装/更新并启动 systemd 服务”。"
  fi
}

show_status() {
  echo
  systemctl status "$SERVICE_NAME.service" --no-pager || true
  echo
  echo "如需查看实时日志：journalctl -u ${SERVICE_NAME}.service -f"
  echo "单条链路日志目录：${LOG_DIR}/"
}

menu() {
  ensure_dependencies
  while true; do
    echo
    echo "========== SSH 隧道转发管理 =========="
    echo "[1] 新增本地转发 (-L)：本机端口 -> SSH服务器 -> 目标"
    echo "[2] 新增远程转发 (-R)：SSH服务器端口 -> 当前机器/内网目标"
    echo "[3] 查看转发链路"
    echo "[4] 删除指定转发链路"
    echo "[5] 清空全部转发链路"
    echo "[6] 安装/更新并启动 systemd 服务"
    echo "[7] 查看服务状态"
    echo "[0] 退出"
    echo "--------------------------------------"
    local choice
    read -r -p "请选择: " choice
    case "$choice" in
      1) add_local_forward ;;
      2) add_remote_forward ;;
      3) list_forwards ;;
      4) delete_forward ;;
      5) clear_all_forwards ;;
      6) install_service ;;
      7) show_status ;;
      0) exit 0 ;;
      *) echo "输入错误，请重新选择。" ;;
    esac
  done
}

case "${1:-menu}" in
  menu) need_root; menu ;;
  list) need_root; list_forwards ;;
  add-local) need_root; ensure_dependencies; add_local_forward ;;
  add-remote) need_root; ensure_dependencies; add_remote_forward ;;
  delete|del|remove) need_root; delete_forward ;;
  service|install-service) need_root; install_service ;;
  status) need_root; show_status ;;
  *) echo "用法: $0 [menu|list|add-local|add-remote|delete|service|status]"; exit 1 ;;
esac
