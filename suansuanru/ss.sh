#!/bin/bash
set -e

SERVICE_BASE_NAME="shadowsocks-rust"
CONFIG_DIR="/etc/shadowsocks-rust"

# 生成符合 2022-blake3 密码（32字节 base64）
generate_password() {
    local method="$1"
    if [[ "$method" =~ ^2022-blake3 ]]; then
        head -c 32 /dev/urandom | base64
    else
        tr -dc 'A-Za-z0-9!@#$%^&*()-_=+' < /dev/urandom | head -c 16
        echo
    fi
}

validate_password() {
    local method="$1"
    local pwd="$2"
    if [[ "$method" =~ ^2022-blake3 ]]; then
        if [[ ${#pwd} -ne 44 ]]; then
            echo "错误：2022-blake3 密码必须是Base64编码的44字符字符串！"
            return 1
        fi
        if ! [[ "$pwd" =~ ^[A-Za-z0-9+/]{43}=$ ]]; then
            echo "错误：密码不符合 Base64 格式！"
            return 1
        fi
    fi
    return 0
}

echo "====== shadowsocks-rust 多端口安装脚本 ======"

read -p "是否配置多个端口？(y/n，默认n): " MULTI
MULTI=${MULTI:-n}

ports=()
passwords=()
methods=()

if [[ "$MULTI" =~ ^[Yy]$ ]]; then
    echo "请输入多个端口，用空格分隔（例 8388 8488）:"
    read -a ports

    for port in "${ports[@]}"; do
        echo -e "\n配置端口: $port"

        echo "选择加密方式:"
        echo "1) chacha20-poly1305"
        echo "2) aes-128-gcm"
        echo "3) aes-256-gcm"
        echo "4) 2022-blake3-aes-128-gcm"
        echo "5) 2022-blake3-chacha20-poly1305"
        echo "6) 2022-blake3-xchacha20-poly1305"
        read -p "输入数字选择(默认1): " method_choice
        case "$method_choice" in
            2) method="aes-128-gcm" ;;
            3) method="aes-256-gcm" ;;
            4) method="2022-blake3-aes-128-gcm" ;;
            5) method="2022-blake3-chacha20-poly1305" ;;
            6) method="2022-blake3-xchacha20-poly1305" ;;
            *) method="chacha20-poly1305" ;;
        esac
        methods+=("$method")

        read -p "是否随机生成密码？(y/n，默认y): " gen_pass
        gen_pass=${gen_pass:-y}
        if [[ "$gen_pass" =~ ^[Yy]$ ]]; then
            pwd=$(generate_password "$method")
            echo "生成密码: $pwd"
        else
            while true; do
                read -s -p "请输入密码：" pwd
                echo
                if [ -z "$pwd" ]; then
                    echo "密码不能为空"
                    continue
                fi
                if ! validate_password "$method" "$pwd"; then
                    echo "请重新输入符合要求的密码"
                    continue
                fi
                break
            done
        fi
        passwords+=("$pwd")
    done

else
    read -p "请输入监听端口（默认8388）: " PORT
    PORT=${PORT:-8388}

    echo "选择加密方式:"
    echo "1) chacha20-poly1305"
    echo "2) aes-128-gcm"
    echo "3) aes-256-gcm"
    echo "4) 2022-blake3-aes-128-gcm"
    echo "5) 2022-blake3-chacha20-poly1305"
    echo "6) 2022-blake3-xchacha20-poly1305"
    read -p "输入数字选择(默认1): " method_choice
    case "$method_choice" in
        2) method="aes-128-gcm" ;;
        3) method="aes-256-gcm" ;;
        4) method="2022-blake3-aes-128-gcm" ;;
        5) method="2022-blake3-chacha20-poly1305" ;;
        6) method="2022-blake3-xchacha20-poly1305" ;;
        *) method="chacha20-poly1305" ;;
    esac

    read -p "是否随机生成密码？(y/n，默认y): " gen_pass
    gen_pass=${gen_pass:-y}
    if [[ "$gen_pass" =~ ^[Yy]$ ]]; then
        pwd=$(generate_password "$method")
        echo "生成密码: $pwd"
    else
        while true; do
            read -s -p "请输入密码：" pwd
            echo
            if [ -z "$pwd" ]; then
                echo "密码不能为空"
                continue
            fi
            if ! validate_password "$method" "$pwd"; then
                echo "请重新输入符合要求的密码"
                continue
            fi
            break
        done
    fi

    ports=("$PORT")
    methods=("$method")
    passwords=("$pwd")

fi

echo "更新软件包索引，安装依赖..."
apt update
apt install -y curl tar xz-utils

echo "获取 shadowsocks-rust 最新版本信息..."
LATEST_RELEASE=$(curl -sL https://api.github.com/repos/shadowsocks/shadowsocks-rust/releases/latest | grep '"tag_name"' | head -n1 | cut -d '"' -f4)
if [ -z "$LATEST_RELEASE" ]; then
    echo "无法获取最新版本，退出"
    exit 1
fi
echo "最新版本: $LATEST_RELEASE"

BIN_NAME="shadowsocks-v${LATEST_RELEASE#v}.x86_64-unknown-linux-gnu.tar.xz"
BIN_URL="https://github.com/shadowsocks/shadowsocks-rust/releases/download/$LATEST_RELEASE/$BIN_NAME"

echo "下载 shadowsocks-rust 二进制文件..."
curl -L -o shadowsocks.tar.xz "$BIN_URL"

echo "解压 shadowsocks-rust..."
mkdir -p shadowsocks
tar -xJf shadowsocks.tar.xz  -C shadowsocks

mv shadowsocks /usr/local/bin/
chmod +x /usr/local/bin/shadowsocks

mkdir -p "$CONFIG_DIR"

declare -a configured_ports
declare -a configured_passwords
declare -a configured_methods
declare -a configured_dns

for i in "${!ports[@]}"; do
    port="${ports[$i]}"
    pwd="${passwords[$i]}"
    method="${methods[$i]}"

    read -p "端口 $port 是否自定义 DNS？(y/n，默认n): " use_dns
    use_dns=${use_dns:-n}
    if [[ "$use_dns" =~ ^[Yy]$ ]]; then
        read -p "请输入 DNS (示例 8.8.8.8): " dns_value
        dns_value=${dns_value:-""}
    else
        dns_value=""
    fi

    config_path="$CONFIG_DIR/config_$port.json"

    # 生成配置文件，未自定义 DNS 时不写 dns 字段，使用系统 DNS
    if [[ -z "$dns_value" ]]; then
        cat > "$config_path" <<EOF
{
  "server": "0.0.0.0",
  "server_port": $port,
  "password": "$pwd",
  "method": "$method",
  "timeout": 300,
  "fast_open": false
}
EOF
    else
        cat > "$config_path" <<EOF
{
  "server": "0.0.0.0",
  "server_port": $port,
  "password": "$pwd",
  "method": "$method",
  "dns": "$dns_value",
  "timeout": 300,
  "fast_open": false
}
EOF
    fi

    service_name="${SERVICE_BASE_NAME}_${port}"
    cat > "/etc/systemd/system/$service_name.service" <<EOF
[Unit]
Description=Shadowsocks-rust proxy server - port $port
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/shadowsocks -c $config_path
Restart=on-failure
User=nobody
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable --now $service_name

    # 记录配置信息
    configured_ports+=("$port")
    configured_passwords+=("$pwd")
    configured_methods+=("$method")
    if [[ -z "$dns_value" ]]; then
        configured_dns+=("(system default)")
    else
        configured_dns+=("$dns_value")
    fi

    echo "端口 $port 的服务已启动，服务名：$service_name"
done

echo
echo "========== Shadowsocks-rust 配置信息 =========="
for i in "${!configured_ports[@]}"; do
    echo "端口: ${configured_ports[$i]}"
    echo "加密方式: ${configured_methods[$i]}"
    echo "密码: ${configured_passwords[$i]}"
    echo "DNS: ${configured_dns[$i]}"
    echo "---------------------------"
done
