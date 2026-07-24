#!/usr/bin/env bash
# install-node-via-nvm.sh
# 自动安装 nvm + 最新 Node.js
set -euo pipefail

# ---------- 配置 ----------
NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
INSTALL_LTS=false          # 默认装 latest；传 --lts 则装 LTS
FORCE_REINSTALL_NVM=false  # 传 --force-nvm 强制重装 nvm

# ---------- 参数解析 ----------
for arg in "$@"; do
  case "$arg" in
    --lts)          INSTALL_LTS=true ;;
    --force-nvm)    FORCE_REINSTALL_NVM=true ;;
    -h|--help)
      cat <<EOF
用法: $0 [选项]
  --lts         安装最新 LTS 版本（默认安装最新正式版）
  --force-nvm   强制重新安装 nvm
  -h, --help    显示帮助
EOF
      exit 0
      ;;
  esac
done

# ---------- 工具函数 ----------
info()  { printf '\033[1;34m[INFO]\033[0m %s\n' "$*"; }
ok()    { printf '\033[1;32m[OK]\033[0m %s\n' "$*"; }
err()   { printf '\033[1;31m[ERR]\033[0m %s\n' "$*" >&2; exit 1; }

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || err "缺少依赖: $1"
}

# ---------- 依赖检查 ----------
need_cmd curl
need_cmd bash

# ---------- 安装 / 加载 nvm ----------
install_nvm() {
  info "正在获取 nvm 最新 release..."
  local tag
  tag=$(curl -fsSL https://api.github.com/repos/nvm-sh/nvm/releases/latest \
        | grep -o '"tag_name": *"[^"]*"' \
        | head -1 \
        | sed 's/.*"\([^"]*\)".*/\1/') || err "无法获取 nvm 最新版本"

  info "安装 nvm ${tag} ..."
  curl -fsSL "https://raw.githubusercontent.com/nvm-sh/nvm/${tag}/install.sh" | bash
  ok "nvm ${tag} 安装完成"
}

load_nvm() {
  export NVM_DIR
  # shellcheck disable=SC1091
  [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
  [ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion" 2>/dev/null || true
  command -v nvm >/dev/null 2>&1 || err "nvm 加载失败，请检查 $NVM_DIR"
}

if [ "$FORCE_REINSTALL_NVM" = true ] || [ ! -s "$NVM_DIR/nvm.sh" ]; then
  install_nvm
fi
load_nvm
ok "nvm 版本: $(nvm --version)"

# ---------- 安装 Node.js ----------
if [ "$INSTALL_LTS" = true ]; then
  info "正在获取并安装最新 LTS Node.js..."
  nvm install --lts
  nvm alias default 'lts/*'
  TARGET="LTS"
else
  info "正在获取并安装最新 Node.js..."
  nvm install node
  nvm alias default node
  TARGET="latest"
fi

nvm use default

# ---------- 结果 ----------
NODE_VER=$(node -v)
NPM_VER=$(npm -v)
REMOTE_LATEST=$(nvm version-remote node 2>/dev/null || echo "N/A")

ok "安装完成"
cat <<EOF

----------------------------------------
  目标类型     : ${TARGET}
  Node.js      : ${NODE_VER}
  npm          : ${NPM_VER}
  远程最新版本 : ${REMOTE_LATEST}
  默认版本     : $(nvm version default)
----------------------------------------

当前 shell 已生效。新开终端请确保已加载 nvm：
  export NVM_DIR="\$HOME/.nvm"
  [ -s "\$NVM_DIR/nvm.sh" ] && . "\$NVM_DIR/nvm.sh"
EOF
