#!/usr/bin/env bash
set -e

echo "🚀 Debian 13 (Trixie) Docker 国内一键安装脚本"
echo "---------------------------------------------"

# 必须 root
if [ "$(id -u)" -ne 0 ]; then
  echo "❌ 请使用 root 用户或 sudo 运行此脚本"
  exit 1
fi

# 基础依赖
echo "📦 安装基础依赖..."
apt update
apt install -y ca-certificates curl gnupg lsb-release

# Docker GPG Key（阿里云）
echo "🔑 添加 Docker GPG Key（阿里云）..."
mkdir -p /etc/apt/keyrings
curl -fsSL https://mirrors.aliyun.com/docker-ce/linux/debian/gpg \
  | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

# Docker 阿里云 APT 源（Debian 13 = trixie）
echo "📡 添加 Docker APT 源（阿里云）..."
cat > /etc/apt/sources.list.d/docker.list <<EOF
deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://mirrors.aliyun.com/docker-ce/linux/debian trixie stable
EOF

# 安装 Docker
echo "🐳 安装 Docker..."
apt update
apt install -y \
  docker-ce \
  docker-ce-cli \
  containerd.io \
  docker-buildx-plugin \
  docker-compose-plugin

# 开机启动
systemctl enable docker
systemctl start docker

# 镜像加速
echo "⚡ 配置 Docker 镜像加速..."
mkdir -p /etc/docker
cat > /etc/docker/daemon.json <<EOF
{
  "registry-mirrors": [
    "https://registry.docker-cn.com",
    "https://docker.mirrors.ustc.edu.cn"
  ]
}
EOF

systemctl daemon-reexec
systemctl restart docker

# 普通用户免 sudo
if [ -n "$SUDO_USER" ]; then
  echo "👤 添加用户 $SUDO_USER 到 docker 用户组..."
  usermod -aG docker "$SUDO_USER"
fi

# 验证
echo "✅ Docker 安装完成，版本信息："
docker version

echo "🎉 安装成功！重新登录即可免 sudo 使用 docker"
