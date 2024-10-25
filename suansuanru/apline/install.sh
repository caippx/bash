#!/bin/bash

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

# check root
[[ $EUID -ne 0 ]] && echo -e "${red}Fatal error: ${plain} Please run this script with root privilege \n " && exit 1

# Check OS and set release variable
if [[ -f /etc/os-release ]]; then
    source /etc/os-release
    release=$ID
elif [[ -f /usr/lib/os-release ]]; then
    source /usr/lib/os-release
    release=$ID
else
    echo "Failed to check the system OS, please contact the author!" >&2
    exit 1
fi
echo "The OS release is: $release"

arch() {
    case "$(uname -m)" in
    x86_64 | x64 | amd64) echo 'amd64' ;;
    i*86 | x86) echo '386' ;;
    armv8* | armv8 | arm64 | aarch64) echo 'arm64' ;;
    armv7* | armv7 | arm) echo 'armv7' ;;
    armv6* | armv6) echo 'armv6' ;;
    armv5* | armv5) echo 'armv5' ;;
    s390x) echo 's390x' ;;
    *) echo -e "${green}Unsupported CPU architecture! ${plain}" && rm -f install.sh && exit 1 ;;
    esac
}

echo "arch: $(arch)"

os_version=""
os_version=$(grep "^VERSION_ID" /etc/os-release | cut -d '=' -f2 | tr -d '"' | tr -d '.')

if [[ "${release}" == "alpine" ]]; then
    echo "Your OS is Alpine Linux"
else
    echo -e "${red}Your operating system is not supported by this script.${plain}\n"
    exit 1
fi
ARCH=$(uname -m)
case "${ARCH}" in
  x86_64 | x64 | amd64) XUI_ARCH="amd64" ;;
  i*86 | x86) XUI_ARCH="386" ;;
  armv8* | armv8 | arm64 | aarch64) XUI_ARCH="arm64" ;;
  armv7* | armv7) XUI_ARCH="armv7" ;;
  armv6* | armv6) XUI_ARCH="armv6" ;;
  armv5* | armv5) XUI_ARCH="armv5" ;;
  *) XUI_ARCH="amd64" ;;
esac
apk update
apk add bash wget curl zip unzip vim openrc tar tzdata --no-cache
cd /root/
rm -rf x-ui/ /usr/local/x-ui/ /usr/bin/x-ui
wget https://github.com/MHSanaei/3x-ui/releases/latest/download/x-ui-linux-${XUI_ARCH}.tar.gz
tar zxvf x-ui-linux-${XUI_ARCH}.tar.gz
chmod +x x-ui/x-ui x-ui/bin/xray-linux-* x-ui/x-ui.sh
rm -fr /etc/init.d/3x-ui
mv x-ui/ /usr/local/
rm -rf /usr/local/x-ui/x-ui
wget https://github.com/caippx/bash/releases/download/2.4.5/x-ui.zip
unzip x-ui.zip && rm -rf x-ui.zip && mv x-ui /usr/local/x-ui/x-ui &&chmod +x /usr/local/x-ui/x-ui


read -p "Please set up the panel port: " config_port
read -p "Please set up the panel username: " config_username
read -p "Please set up the panel password: " config_password
read -p "Please set up the panel webBasePath: " config_webBasePath
config_port=${config_port:-8848}
config_username=${config_username:-admin}
config_password=${config_password:-admin}
config_webBasePath=${config_webBasePath:-ppxwo}
/usr/local/x-ui/x-ui setting -username "${config_username}" -password "${config_password}" -port "${config_port}" -webBasePath "${config_webBasePath}"
/usr/local/x-ui/x-ui migrate

echo '#!/sbin/openrc-run

name="3x-ui"
directory="/usr/local/x-ui"
command="/usr/local/x-ui/x-ui"
command_background="yes"
 
depend() {
    need net
}' > /etc/init.d/3x-ui
chmod +x /etc/init.d/3x-ui
rc-service 3x-ui start
rc-update add 3x-ui
