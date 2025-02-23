#!/bin/bash
#哪吒V0_
# Copying by nezhahq/scriptgen. DO NOT EDIT

NZ_BASE_PATH="/opt/nezha"
NZ_AGENT_PATH="${NZ_BASE_PATH}/agent"

pre(){

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

install_base() {
    (command -v curl >/dev/null 2>&1 && command -v wget >/dev/null 2>&1 && command -v unzip >/dev/null 2>&1 && command -v getenforce >/dev/null 2>&1) ||
        (install_soft curl wget unzip)
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

install_base
selinux
_version="v0.20.5"
sudo mkdir -p $NZ_AGENT_PATH
echo "正在下载监控端"
printf "是否选用加速镜像完成安装? [Y/n] "
read -r input
 case $input in
  [yY][eE][sS] | [yY])
  echo "使用加速镜像"
  CN=true
  ;;
  [nN][oO] | [nN])
   echo "不加速中国镜像"
   ;;
   esac
if [ -z "$CN" ]; then
NZ_AGENT_URL="https://ghproxy.11451185.xyz/github.com/nezhahq/agent/releases/download/${_version}/nezha-agent_linux_${os_arch}.zip"
else
NZ_AGENT_URL="https://${GITHUB_URL}/nezhahq/agent/releases/download/${_version}/nezha-agent_linux_${os_arch}.zip"
fi
