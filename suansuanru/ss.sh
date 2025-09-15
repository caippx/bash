#!/bin/bash
set -e

SERVICE_BASE_NAME="shadowsocks-rust"
CONFIG_DIR="/etc/shadowsocks-rust"
BIN_DIR="/usr/local/bin"
BIN_PATH="$BIN_DIR/ssserver"

# 检测系统类型
detect_system() {
    if [ -f /etc/alpine-release ]; then
        echo "alpine"
    elif [ -f /etc/debian_version ]; then
        echo "debian"
    elif [ -f /etc/redhat-release ]; then
        echo "redhat"
    else
        echo "unknown"
    fi
}

SYSTEM_TYPE=$(detect_system)

# 生成密码函数
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

check_required_tools() {
    local missing_tools=()
    
    for tool in curl tar xz; do
        if ! command -v "$tool" >/dev/null 2>&1; then
            missing_tools+=("$tool")
        fi
    done
    
    if [ ${#missing_tools[@]} -gt 0 ]; then
        echo "缺少必要工具: ${missing_tools[*]}"
        return 1
    fi
    return 0
}

install_dependencies() {
    echo "检查必要工具..."
    if check_required_tools; then
        echo "所有必要工具已安装"
        return 0
    fi
    
    echo "更新软件包索引，安装依赖..."
    case "$SYSTEM_TYPE" in
        alpine)
            if ! apk update; then
                echo "更新软件包索引失败"
                exit 1
            fi
            if ! apk add --no-cache curl tar xz; then
                echo "安装依赖失败"
                exit 1
            fi
            ;;
        debian)
            if ! apt update; then
                echo "更新软件包索引失败"
                exit 1
            fi
            if ! apt install -y curl tar xz-utils; then
                echo "安装依赖失败"
                exit 1
            fi
            ;;
        redhat)
            if ! yum update -y; then
                echo "更新软件包索引失败"
                exit 1
            fi
            if ! yum install -y curl tar xz; then
                echo "安装依赖失败"
                exit 1
            fi
            ;;
        *)
            echo "不支持的系统类型，请手动安装 curl, tar, xz"
            exit 1
            ;;
    esac
    
    # 再次检查工具是否安装成功
    if ! check_required_tools; then
        echo "依赖安装后仍有工具缺失，请手动安装"
        exit 1
    fi
    echo "依赖安装完成"
}

download_and_install_binary() {
    install_dependencies

    echo "获取 shadowsocks-rust 最新版本信息..."
    LATEST_RELEASE=$(curl -sL https://api.github.com/repos/shadowsocks/shadowsocks-rust/releases/latest | grep '"tag_name"' | head -n1 | cut -d '"' -f4)
    if [ -z "$LATEST_RELEASE" ]; then
        echo "无法获取最新版本，退出"
        exit 1
    fi
    echo "最新版本: $LATEST_RELEASE"

    # 根据系统类型选择正确的二进制文件
    if [ "$SYSTEM_TYPE" = "alpine" ]; then
        BIN_NAME="shadowsocks-v${LATEST_RELEASE#v}.x86_64-unknown-linux-musl.tar.xz"
    else
        BIN_NAME="shadowsocks-v${LATEST_RELEASE#v}.x86_64-unknown-linux-gnu.tar.xz"
    fi
    BIN_URL="https://github.com/shadowsocks/shadowsocks-rust/releases/download/$LATEST_RELEASE/$BIN_NAME"

    echo "下载 shadowsocks-rust 二进制文件 ($BIN_NAME)..."
    if ! curl -L -o shadowsocks.tar.xz "$BIN_URL"; then
        echo "下载失败，请检查网络连接或版本信息"
        exit 1
    fi

    echo "解压 shadowsocks-rust..."
    mkdir -p shadowsocks-temp
    if ! tar -xJf shadowsocks.tar.xz -C shadowsocks-temp; then
        echo "解压失败，文件可能损坏"
        rm -rf shadowsocks-temp shadowsocks.tar.xz
        exit 1
    fi

    # 修复：正确处理二进制文件路径
    mkdir -p "$BIN_DIR"
    if [ ! -f "shadowsocks-temp/ssserver" ]; then
        echo "错误：解压后未找到 ssserver 二进制文件"
        rm -rf shadowsocks-temp shadowsocks.tar.xz
        exit 1
    fi
    cp shadowsocks-temp/ssserver "$BIN_PATH"
    chmod +x "$BIN_PATH"

    rm -rf shadowsocks-temp shadowsocks.tar.xz

    # 设置网络参数（如果支持）
    if [ -f /proc/sys/net/ipv6/bindv6only ]; then
        sysctl -w net.ipv6.bindv6only=0 2>/dev/null || true
    fi
    
    echo "shadowsocks-rust 二进制文件安装完成"
}

create_systemd_service() {
    local port=$1
    local config_path=$2
    local service_name="${SERVICE_BASE_NAME}_${port}"
    
    cat > "/etc/systemd/system/$service_name.service" <<EOF
[Unit]
Description=Shadowsocks-rust proxy server - port $port
After=network.target

[Service]
Type=simple
ExecStart=$BIN_PATH -c $config_path
Restart=on-failure
User=nobody
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable --now "$service_name"
    echo "systemd 服务 $service_name 启动成功"
}

create_openrc_service() {
    local port=$1
    local config_path=$2
    local service_name="${SERVICE_BASE_NAME}_${port}"
    local service_file="/etc/init.d/$service_name"
    
    cat > "$service_file" <<EOF
#!/sbin/openrc-run

name="Shadowsocks-rust proxy server - port $port"
description="Shadowsocks-rust proxy server"
command="$BIN_PATH"
command_args="-c $config_path"
command_user="nobody"
pidfile="/var/run/\${RC_SVCNAME}.pid"
command_background="yes"

depend() {
    need net
    after firewall
}
EOF

    chmod +x "$service_file"
    rc-update add "$service_name" default
    rc-service "$service_name" start
    echo "OpenRC 服务 $service_name 启动成功"
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

    # 根据系统类型创建服务
    case "$SYSTEM_TYPE" in
        alpine)
            create_openrc_service "$port" "$config_path"
            ;;
        debian|redhat)
            create_systemd_service "$port" "$config_path"
            ;;
        *)
            echo "警告：未知系统类型，无法创建系统服务"
            echo "配置文件已创建：$config_path"
            echo "请手动运行：$BIN_PATH -c $config_path"
            ;;
    esac
}

remove_systemd_service() {
    local port=$1
    local service_name="${SERVICE_BASE_NAME}_${port}"
    
    echo "停止并禁用 systemd 服务 $service_name"
    systemctl stop "$service_name" 2>/dev/null || true
    systemctl disable "$service_name" 2>/dev/null || true
    rm -f "/etc/systemd/system/$service_name.service"
    systemctl daemon-reload
}

remove_openrc_service() {
    local port=$1
    local service_name="${SERVICE_BASE_NAME}_${port}"
    
    echo "停止并禁用 OpenRC 服务 $service_name"
    rc-service "$service_name" stop 2>/dev/null || true
    rc-update del "$service_name" default 2>/dev/null || true
    rm -f "/etc/init.d/$service_name"
}

remove_service_and_config() {
    local port=$1
    
    # 根据系统类型删除服务
    case "$SYSTEM_TYPE" in
        alpine)
            remove_openrc_service "$port"
            ;;
        debian|redhat)
            remove_systemd_service "$port"
            ;;
        *)
            echo "警告：未知系统类型，请手动停止服务"
            ;;
    esac

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

支持系统: Alpine Linux, Debian/Ubuntu, CentOS/RHEL

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
        if [[ ! "$port" =~ ^[0-9]+$ ]]; then
            echo "输入端口号错误，请输入数字"
            continue
        fi
        if [ "$port" -lt 1 ] || [ "$port" -gt 65535 ]; then
            echo "端口号必须在 1-65535 范围内"
            continue
        fi
        # 检查端口是否已被占用
        if netstat -tuln 2>/dev/null | grep -q ":$port "; then
            echo "警告：端口 $port 可能已被占用"
            read -p "是否继续使用此端口？(y/n): " continue_port
            if [[ ! "$continue_port" =~ ^[Yy]$ ]]; then
                continue
            fi
        fi
        # 检查配置文件是否已存在
        if [ -f "$CONFIG_DIR/config_$port.json" ]; then
            echo "警告：端口 $port 的配置文件已存在"
            read -p "是否覆盖现有配置？(y/n): " overwrite_config
            if [[ ! "$overwrite_config" =~ ^[Yy]$ ]]; then
                continue
            fi
        fi
        break
    done

    # 加密方式
    echo 
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

    export PROMPT_PORT="$port"
    export PROMPT_METHOD="$method"
    export PROMPT_PWD="$pwd"
    export PROMPT_DNS="$dns_value"
}

do_install() {
    echo "检测到系统类型: $SYSTEM_TYPE"
    download_and_install_binary

    read -p "是否配置多个端口？(y/n，默认n): " MULTI
    MULTI=${MULTI:-n}

    if [[ "$MULTI" =~ ^[Yy]$ ]]; then
        echo "请输入多个端口，用空格分隔（例 8388 8389）:"
        read -a ports

        # 验证所有端口
        for port in "${ports[@]}"; do
            if [[ ! "$port" =~ ^[0-9]+$ ]]; then
                echo "错误：端口 '$port' 不是有效数字"
                exit 1
            fi
            if [ "$port" -lt 1 ] || [ "$port" -gt 65535 ]; then
                echo "错误：端口 $port 必须在 1-65535 范围内"
                exit 1
            fi
        done

        declare -a passwords
        declare -a methods
        declare -a dns_values

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
            echo "[$((i+1))] 端口：${ports[$i]}"
            echo "    加密方式：${methods[$i]}"
            echo "    密码：${passwords[$i]}"
            echo "    DNS：${dns_values[$i]:-(system default)}"
            echo "-------------------------------"
        done

    else
        # 单端口快速配置
        echo
        prompt_for_port_method_password_dns
        port="$PROMPT_PORT"
        method="$PROMPT_METHOD"
        pwd="$PROMPT_PWD"
        dns_value="$PROMPT_DNS"

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

    # 修复：正确调用函数
    prompt_for_port_method_password_dns
    port="$PROMPT_PORT"
    method="$PROMPT_METHOD"
    pwd="$PROMPT_PWD"
    dns_value="$PROMPT_DNS"
    
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
        
        # 根据系统类型检查服务是否存在
        service_exists=false
        config_exists=false
        
        case "$SYSTEM_TYPE" in
            alpine)
                if [ -f "/etc/init.d/$service_name" ]; then
                    service_exists=true
                fi
                ;;
            debian|redhat)
                if [ -f "/etc/systemd/system/$service_name.service" ]; then
                    service_exists=true
                fi
                ;;
        esac
        
        # 检查配置文件是否存在
        if [ -f "$CONFIG_DIR/config_$port.json" ]; then
            config_exists=true
        fi
        
        if [ "$service_exists" = false ] && [ "$config_exists" = false ]; then
            echo "未发现端口 $port 的服务或配置文件，确认重新输入？(y/n)"
            read -r yn
            if [[ "$yn" != "y" && "$yn" != "Y" ]]; then
                echo "退出卸载"
                exit 0
            fi
            continue
        fi
        
        if [ "$service_exists" = true ] || [ "$config_exists" = true ]; then
            echo "找到端口 $port 的配置，开始卸载..."
            remove_service_and_config "$port"
        fi
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
