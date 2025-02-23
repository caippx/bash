#!/bin/bash
#哪吒V0_
# Copying by nezhahq/scriptgen. DO NOT EDIT

NZ_BASE_PATH="/opt/nezha"
NZ_DASHBOARD_PATH="${NZ_BASE_PATH}/dashboard"
NZ_AGENT_PATH="${NZ_BASE_PATH}/agent"
NZ_DASHBOARD_SERVICE="/etc/systemd/system/nezha-dashboard.service"
NZ_DASHBOARD_SERVICERC="/etc/init.d/nezha-dashboard"
GITHUB_RAW_URL="raw.githubusercontent.com/nezhahq/scripts/v0"
GITHUB_URL="github.com"
Get_Docker_URL="get.docker.com"
Get_Docker_Argu=" "
Docker_IMG="ghcr.io\/naiba\/nezha-dashboard:v0.20.13"

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'
export PATH="$PATH:/usr/local/bin"

check_systemd() {
    if [ "$os_alpine" != 1 ] && ! command -v systemctl >/dev/null 2>&1; then
        echo "不支持此系统：未找到 systemctl 命令"
        exit 1
    fi
}

err() {
    printf "${red}%s${plain}\n" "$*" >&2
}

success() {
    printf "${green}%s${plain}\n" "$*"
}

info() {
    printf "${yellow}%s${plain}\n" "$*"
}


before_show_menu() {
    echo && info "* 按回车返回主菜单 *" && read temp
    show_menu
}


install_base() {
    (command -v curl >/dev/null 2>&1 && command -v wget >/dev/null 2>&1 && command -v unzip >/dev/null 2>&1 && command -v getenforce >/dev/null 2>&1) ||
        (install_soft curl wget unzip)
}
install_soft() {
    (command -v yum >/dev/null 2>&1 && sudo yum makecache && sudo yum install "$@" selinux-policy -y) ||
        (command -v apt >/dev/null 2>&1 && sudo apt update && sudo apt install "$@" selinux-utils -y) ||
        (command -v pacman >/dev/null 2>&1 && sudo pacman -Syu "$@" base-devel --noconfirm && install_arch) ||
        (command -v apt-get >/dev/null 2>&1 && sudo apt-get update && sudo apt-get install "$@" selinux-utils -y) ||
        (command -v apk >/dev/null 2>&1 && sudo apk update && sudo apk add "$@" -f)
}


selinux() {
    #Check SELinux
    if command -v getenforce >/dev/null 2>&1; then
        if getenforce | grep '[Ee]nfor'; then
            echo "SELinux是开启状态，正在关闭！"
            sudo setenforce 0 >/dev/null 2>&1
            find_key="SELINUX="
            sudo sed -ri "/^$find_key/c${find_key}disabled" /etc/selinux/config
        fi
    fi
}

pre() {
    umask 077
    ## os_arch
    if uname -m | grep -q 'x86_64'; then
        os_arch="amd64"
    elif uname -m | grep -q 'i386\|i686'; then
        os_arch="386"
    elif uname -m | grep -q 'aarch64\|armv8b\|armv8l'; then
        os_arch="arm64"
    elif uname -m | grep -q 'arm'; then
        os_arch="arm"
    elif uname -m | grep -q 's390x'; then
        os_arch="s390x"
    elif uname -m | grep -q 'riscv64'; then
        os_arch="riscv64"
    fi
}

install_agent() {
    install_base
    selinux
    pre

    echo "> 安装监控Agent"

    # echo "正在获取监控Agent版本号"

    _version="v0.20.5"
    # Nezha Monitoring Folder
    sudo mkdir -p $NZ_AGENT_PATH
    echo "正在下载监控端"
    printf "是否选用加速镜像完成安装? [Y/n] "
    read -r input
     case $input in
      [yY][eE][sS] | [yY])
          echo "使用加速镜像"
          CN=true
          NZ_AGENT_URL="https://ghproxy.11451185.xyz/${GITHUB_URL}/nezhahq/agent/releases/download/${_version}/nezha-agent_linux_${os_arch}.zip"
          ;;
      [nN][oO] | [nN])
           echo "不加速中国镜像"
           NZ_AGENT_URL="https://${GITHUB_URL}/nezhahq/agent/releases/download/${_version}/nezha-agent_linux_${os_arch}.zip"
           ;;
       esac

    _cmd="wget -t 2 -T 60 -O nezha-agent_linux_${os_arch}.zip $NZ_AGENT_URL >/dev/null 2>&1"
    if ! eval "$_cmd"; then
        err "Release 下载失败，请检查本机能否连接 ${GITHUB_URL}"
        return 1
    fi

    sudo unzip -qo nezha-agent_linux_${os_arch}.zip &&
        sudo mv nezha-agent $NZ_AGENT_PATH &&
        sudo rm -rf nezha-agent_linux_${os_arch}.zip README.md

    if [ $# -ge 3 ]; then
        modify_agent_config "$@"
    else
        modify_agent_config 0
    fi

    if [ $# = 0 ]; then
        before_show_menu
    fi
}

modify_agent_config() {
    echo "> 修改 Agent 配置"

    if [ $# -lt 3 ]; then
        echo "请先在管理面板上添加Agent，记录下密钥"
            printf "请输入一个解析到面板所在IP的域名（不可套CDN）: "
            read -r nz_grpc_host
            printf "请输入面板RPC端口 (默认值 5555): "
            read -r nz_grpc_port
            printf "请输入Agent 密钥: "
            read -r nz_client_secret
            printf "是否启用针对 gRPC 端口的 SSL/TLS加密 (--tls)，需要请按 [y]，默认是不需要，不理解用户可回车跳过: "
            read -r nz_grpc_proxy
        echo "${nz_grpc_proxy}" | grep -qiw 'Y' && args='--tls'
        if [ -z "$nz_grpc_host" ] || [ -z "$nz_client_secret" ]; then
            err "所有选项都不能为空"
            before_show_menu
            return 1
        fi
        if [ -z "$nz_grpc_port" ]; then
            nz_grpc_port=5555
        fi
    else
        nz_grpc_host=$1
        nz_grpc_port=$2
        nz_client_secret=$3
        shift 3
        if [ $# -gt 0 ]; then
            args="$*"
        fi
    fi

    _cmd="sudo ${NZ_AGENT_PATH}/nezha-agent service install -s $nz_grpc_host:$nz_grpc_port -p $nz_client_secret $args >/dev/null 2>&1"

    if ! eval "$_cmd"; then
        sudo "${NZ_AGENT_PATH}"/nezha-agent service uninstall >/dev/null 2>&1
        sudo "${NZ_AGENT_PATH}"/nezha-agent service install -s "$nz_grpc_host:$nz_grpc_port" -p "$nz_client_secret" "$args" >/dev/null 2>&1
    fi
    
    success "Agent 配置 修改成功，请稍等 Agent 重启生效"

    #if [[ $# == 0 ]]; then
    #    before_show_menu
    #fi
}

show_agent_log() {
    echo "> 获取 Agent 日志"

    if [ "$os_alpine" != 1 ]; then
        sudo journalctl -xf -u nezha-agent.service
    else
        sudo tail -n 10 /var/log/nezha-agent.err
    fi

    if [ $# = 0 ]; then
        before_show_menu
    fi
}

uninstall_agent() {
    echo "> 卸载 Agent"

    sudo ${NZ_AGENT_PATH}/nezha-agent service uninstall

    sudo rm -rf $NZ_AGENT_PATH
    clean_all

    if [ $# = 0 ]; then
        before_show_menu
    fi
}

restart_agent() {
    echo "> 重启 Agent"

    sudo ${NZ_AGENT_PATH}/nezha-agent service restart

    if [ $# = 0 ]; then
        before_show_menu
    fi
}

clean_all() {
    if [ -z "$(ls -A ${NZ_BASE_PATH})" ]; then
        sudo rm -rf ${NZ_BASE_PATH}
    fi
}

show_menu() {
    printf "
    ${green}哪吒监控管理脚本 For v0${plain}
    --- https://github.com/naiba/nezha ---
    ${red}v0面板已停止维护，请及时升级至v1，详见https://nezha.wiki/${plain}
    ${green}1.${plain}  安装监控Agent
    ${green}2.${plain}  修改Agent配置
    ${green}3.${plain} 查看Agent日志
    ${green}4.${plain} 卸载Agent
    ${green}5.${plain} 重启Agent
    ————————————————-
    ${green}0.${plain}  退出脚本
    "
    echo && printf "请输入选择 [0-13]: " && read -r num
    case "${num}" in
        0)
            exit 0
            ;;
        1)
            install_agent
            ;;
        2)
            modify_agent_config
            ;;
        3)
            show_agent_log
            ;;
        4)
            uninstall_agent
            ;;
        5)
            restart_agent
            ;;
        *)
            err "请输入正确的数字 [0-13]"
            ;;
    esac
}


if [ $# -gt 0 ]; then
    case $1 in
        "install_agent")
            shift
            if [ $# -ge 3 ]; then
                install_agent "$@"
            else
                install_agent 0
            fi
            ;;
        "modify_agent_config")
            modify_agent_config 0
            ;;
        "show_agent_log")
            show_agent_log 0
            ;;
        "uninstall_agent")
            uninstall_agent 0
            ;;
        "restart_agent")
            restart_agent 0
            ;;
        *) show_usage ;;
    esac
else
    select_version
    show_menu
fi
