#!/usr/bin/env bash
set -euo pipefail

############################################
# 基础函数
############################################
msg() { echo -e "\033[1;32m[INFO]\033[0m $*"; }
warn() { echo -e "\033[1;33m[WARN]\033[0m $*"; }
err() { echo -e "\033[1;31m[ERR ]\033[0m $*"; exit 1; }

############################################
# Root 检查
############################################
[ "$(id -u)" -eq 0 ] || err "请使用 root 或 sudo 执行"

############################################
# 系统检测
############################################
. /etc/os-release || err "无法读取系统信息"

msg "系统: $NAME"
msg "系统ID: $ID"
msg "版本代号: ${VERSION_CODENAME:-unknown}"

[[ "$ID" == "debian" || "$ID" == "ubuntu" ]] || err "仅支持 Debian / Ubuntu"

# Debian testing 兜底
if [ -z "${VERSION_CODENAME:-}" ] && [ "$ID" = "debian" ]; then
  VERSION_CODENAME="trixie"
  warn "未检测到 Debian 代号，默认使用 trixie"
fi

############################################
# 判断是否中国大陆
############################################
msg "判断服务器网络位置..."
COUNTRY=$(curl -fsSL https://ipinfo.io/country 2>/dev/null || true)

if [ "$COUNTRY" = "CN" ]; then
  IN_CHINA=true
  msg "检测到中国大陆网络"
else
  IN_CHINA=false
  msg "检测到海外网络（或无法判断）"
fi

############################################
# 基础工具
############################################
msg "安装基础依赖..."
apt update
apt install -y ca-certificates curl gnupg lsb-release

############################################
# Docker 安装
############################################
if [ "$IN_CHINA" = true ]; then
  msg "使用阿里云 Docker APT 源"

  mkdir -p /etc/apt/keyrings
  curl -fsSL https://mirrors.aliyun.com/docker-ce/linux/$ID/gpg \
    | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  chmod a+r /etc/apt/keyrings/docker.gpg

  cat > /etc/apt/sources.list.d/docker.list <<EOF
deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://mirrors.aliyun.com/docker-ce/linux/$ID \
$VERSION_CODENAME stable
EOF

  apt update
  apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
else
  msg "使用 Docker 官方脚本"
  curl -fsSL https://get.docker.com | bash
fi

############################################
# Docker 基础配置（通用）
############################################
msg "配置 Docker 参数"
mkdir -p /etc/docker

cat > /etc/docker/daemon.json <<EOF
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m",
    "max-file": "5"
  }
  $( [ "$IN_CHINA" = true ] && echo ',
  "registry-mirrors": [
    "https://docker.mirrors.sjtug.sjtu.edu.cn",
    "https://docker.nju.edu.cn"
  ]' )
}
EOF

systemctl daemon-reexec
systemctl enable docker
systemctl restart docker

############################################
# 内核 & 系统优化（容器推荐）
############################################
msg "应用系统优化参数"

cat > /etc/sysctl.d/99-docker.conf <<EOF
net.ipv4.ip_forward=1
net.bridge.bridge-nf-call-iptables=1
net.bridge.bridge-nf-call-ip6tables=1
fs.inotify.max_user_instances=8192
fs.inotify.max_user_watches=1048576
vm.overcommit_memory=1
EOF

sysctl --system >/dev/null

############################################
# 文件描述符优化
############################################
cat > /etc/security/limits.d/docker.conf <<EOF
* soft nofile 1048576
* hard nofile 1048576
EOF

############################################
# 安装验证
############################################
msg "Docker 版本信息"
docker version

msg "✅ 所有步骤完成！"
msg "✅ docker安装成功"
