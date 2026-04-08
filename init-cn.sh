############################################
# 开发语言包管理器镜像切换（中国大陆）
############################################

if [ "$IN_CHINA" = true ]; then
  msg "配置开发语言国内镜像（pip / npm / go / cargo）"

  ####################
  # pip
  ####################
  if command -v pip3 >/dev/null 2>&1 || command -v pip >/dev/null 2>&1; then
    msg "→ 配置 pip 国内源（阿里云）"
    mkdir -p /etc/pip
    cat > /etc/pip.conf <<EOF
[global]
index-url = https://mirrors.aliyun.com/pypi/simple
trusted-host = mirrors.aliyun.com
timeout = 60
EOF
  else
    warn "pip 未安装，跳过"
  fi

  ####################
  # npm
  ####################
  if command -v npm >/dev/null 2>&1; then
    msg "→ 配置 npm 国内源（npmmirror）"
    npm config set registry https://registry.npmmirror.com
  else
    warn "npm 未安装，跳过"
  fi

  ####################
  # Golang
  ####################
  if command -v go >/dev/null 2>&1; then
    msg "→ 配置 Go proxy（官方中国推荐）"
    go env -w GOPROXY=https://goproxy.cn,direct
    go env -w GOSUMDB=sum.golang.google.cn
  else
    warn "go 未安装，跳过"
  fi

  ####################
  # Cargo (Rust)
  ####################
  if command -v cargo >/dev/null 2>&1; then
    msg "→ 配置 Cargo 国内源（rsproxy）"
    mkdir -p /root/.cargo
    cat > /root/.cargo/config.toml <<EOF
[source.crates-io]
replace-with = "rsproxy"

[source.rsproxy]
registry = "https://rsproxy.cn/crates.io-index"

[registries.rsproxy]
index = "https://rsproxy.cn/crates.io-index"
EOF
  else
    warn "cargo 未安装，跳过"
  fi
else
  msg "海外环境，保持官方语言源配置"
fi
