#!/usr/bin/env bash
set -e

echo "🌍 判断服务器网络环境..."

# 获取国家代码（CN / US / SG 等）
COUNTRY_CODE=$(curl -fsSL https://ipinfo.io/country || echo "UNKNOWN")

echo "📍 当前服务器国家代码: $COUNTRY_CODE"

if [ "$COUNTRY_CODE" = "CN" ]; then
  echo "🇨🇳 检测到中国大陆网络，使用国内 Docker 安装脚本"
  curl -fsSL https://raw.githubusercontent.com/caippx/bash/refs/heads/master/docker/docker-cn.sh | bash
else
  echo "🌍 非中国大陆网络，使用 Docker 官方安装脚本"
  curl -fsSL https://get.docker.com | bash
fi
