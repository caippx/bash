#!/bin/bash
set -e

SERVICE_BASE_NAME="shadowsocks-rust"
CONFIG_DIR="/etc/shadowsocks-rust"
BIN_DIR="/usr/local/bin"
BIN_PATH="$BIN_DIR/shadowsocks"

# 生成密码函数（和校验保持你脚本中逻辑）
generate_password() {
    local method="$1"
    local length

    case "$method" in
        2022-blake3-aes-128-gcm)
            length=16
            ;;
        2022-blake3-chacha20-poly1305|2022-blake3-xchacha20-poly1305)
            length=32
            ;;
        *)
            length=16
            ;;
    esac

    head -c "$length" /dev/urandom | base64
}

validate_password() {
    local method="$1"
    local pwd="$2"
    local expected_length

    case "$method" in
        2022-blake3-aes-128-gcm)
            expected_length=24
            ;;
        2022-blake3-chacha20-poly1305|2022-blake3-xchacha20-poly1305)
            expected_length=44
            ;;
        *)
            return 0
            ;;
    esac

    if [[ ${#pwd} -ne "$expected_length" ]]; then
        echo "错误：$method 密码必须是Base64编码的${expected_length}字符字符串"
        return 1
    fi

    if ! [[ "$pwd" =~ ^[A-Za-z0-9+/]+=*$ ]]; then
        echo "错误：密码不符合 Base64 格式！"
        return 1
    fi

    return 0
}

download_and_install_binary() {
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
    mkdir -p shadowsocks-temp
    tar -xJf shadowsocks.tar.xz -C shadowsocks-temp

    mv shadowsocks-temp "$BIN_PATH"
    chmod +x "$BIN_PATH"

    rm -rf shadowsocks-temp shadowsocks.tar.xz

    sysctl -w net.ipv6.bindv6only=0
}

create_service_and_config() {
    local port=$1
    local method=$2
    local pwd=$3
    local dns_value=$4

    mkdir -p "$CONFIG_DIR"
    local config_path="$CONFIG_DIR/config_$port.json"

    if [[ -z "$dns_value" ]]; then
        cat > "$config_path" <<EOF
{
  "server": "::",
  "server_port": $port,
  "password": "$pwd",
  "method": "$method",
  "timeout": 300,
  "fast_open": true,
  "mode": "tcp_and_udp",
  "user": "nobody"
}
EOF
    else
        cat > "$config_path" <<EOF
{
  "server": "::",
  "server_port": $port,
  "password": "$pwd",
  "method": "$method",
  "dns": "$dns_value",
  "timeout": 300,
  "fast_open": true,
  "mode": "tcp_and_udp",
  "user": "nobody"
}
EOF
    fi

    local service_name="${SERVICE_BASE_NAME}_${port}"
    cat > "/etc/systemd/system/$service_name.service" <<EOF
[Unit]
Description=Shadowsocks-rust proxy server - port $port
After=network.target

[Service]
Type=simple
ExecStart=$BIN_PATH/ssserver -c $config_path
Restart=on-failure
User=nobody
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable --now "$service_name"
    echo "服务 $service_name 启动成功"
}

remove_service_and_config() {
    local port=$1
    local service_name="${SERVICE_BASE_NAME}_${port}"
    echo "停止并禁用服务 $service_name"
    systemctl stop "$service_name" || true
    systemctl disable "$service_name" || true
    rm -f "/etc/systemd/system/$service_name.service"
    systemctl daemon-reload

    local config_path="$CONFIG_DIR/config_$port.json"
    echo "删除配置文件 $config_path"
    rm -f "$config_path"

    echo "卸载完毕"
}

show_usage() {
    cat <<EOF
用法: $0 {install|add|uninstall}

install  - 首次安装 shadowsocks-rust 并配置一个或多个端口
add      - 新增一个端口配置与服务
uninstall- 卸载指定端口服务和配置

示例:
  $0 install
  $0 add
  $0 uninstall

EOF
}

prompt_for_port_method_password_dns() {
    # 端口
    while true; do
        read -p "请输入端口号: " port
        [[ "$port" =~ ^[0-9]+$ ]] && break || echo "输入端口号错误，请输入数字"
    done

    # 加密方式
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

    # 密码
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

    # DNS
    read -p "是否自定义 DNS？(y/n，默认n): " use_dns
    use_dns=${use_dns:-n}
    if [[ "$use_dns" =~ ^[Yy]$ ]]; then
        read -p "请输入 DNS (多个DNS用逗号分隔): " dns_value
    else
        dns_value=""
    fi

    echo "$port|$method|$pwd|$dns_value"
}

do_install() {
    download_and_install_binary

    read -p "是否配置多个端口？(y/n，默认n): " MULTI
    MULTI=${MULTI:-n}

    if [[ "$MULTI" =~ ^[Yy]$ ]]; then
        echo "请输入多个端口，用空格分隔（例 8388 8389）:"
        read -a ports

        declare -a passwords
        declare -a methods
        declare -a dns_values

        for port in "${ports[@]}"; do
            echo -e "\n配置端口: $port"
            # 使用提示，要求手动输入密码/方法/DNS：
            # 也可以复用 prompt_for_port_method_password_dns 但此处端口已知，简单处理：

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

            read -p "是否自定义 DNS？(y/n，默认n): " use_dns
            use_dns=${use_dns:-n}
            if [[ "$use_dns" =~ ^[Yy]$ ]]; then
                read -p "请输入 DNS (多个DNS用逗号分隔): " dns_value
            else
                dns_value=""
            fi

            passwords+=("$pwd")
            methods+=("$method")
            dns_values+=("$dns_value")
        done

        echo
        echo "开始创建配置和启动服务..."
        for i in "${!ports[@]}"; do
            create_service_and_config "${ports[$i]}" "${methods[$i]}" "${passwords[$i]}" "${dns_values[$i]}"
        done
        
        echo
        echo "安装完成，配置端口信息如下："
        for i in "${!ports[@]}"; do
            echo "[$i] 端口：${ports[$i]}"
            echo "    加密方式：${methods[$i]}"
            echo "    密码：${passwords[$i]}"
            echo "    DNS：${dns_values[$i]:-(system default)}"
            echo "-------------------------------"
        done

    else
        # 单端口快速配置
        port=0; method=""; pwd=""; dns_value=""
        read -r port method pwd dns_value <<< "$(prompt_for_port_method_password_dns)"

        download_and_install_binary
        create_service_and_config "$port" "$method" "$pwd" "$dns_value"

        echo
        echo "服务 $port 配置完成："
        echo "加密方式：$method"
        echo "密码：$pwd"
        echo "DNS：${dns_value:-(system default)}"
    fi
}

do_add() {
    echo "添加新端口配置"

    read -r port method pwd dns_value <<< "$(prompt_for_port_method_password_dns)"
    create_service_and_config "$port" "$method" "$pwd" "$dns_value"

    echo
    echo "服务 $port 新增完成："
    echo "加密方式：$method"
    echo "密码：$pwd"
    echo "DNS：${dns_value:-(system default)}"
}

do_uninstall() {
    # 卸载指定端口服务和配置
    while true; do
        read -p "请输入要卸载的端口: " port
        if [[ ! "$port" =~ ^[0-9]+$ ]]; then
            echo "请输入有效的端口数字"
            continue
        fi
        service_name="${SERVICE_BASE_NAME}_${port}"
        if ! systemctl list-unit-files | grep -qw "$service_name.service"; then
            echo "未发现端口 $port 的服务，确认重新输入？(y/n)"
            read -r yn
            if [[ "$yn" != "y" && "$yn" != "Y" ]]; then
                echo "退出卸载"
                exit 0
            fi
            continue
        fi
        remove_service_and_config "$port"
        break
    done
}

main() {
    if [[ $# -ne 1 ]]; then
        show_usage
        exit 1
    fi

    case "$1" in
        install)
            do_install
            ;;
        add)
            do_add
            ;;
        uninstall)
            do_uninstall
            ;;
        *)
            show_usage
            exit 1
            ;;
    esac
}

main "$@"
