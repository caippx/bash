

echo "deb http://cdn-aws.deb.debian.org/debian testing main" >> /etc/apt/sources.list

apt update -y

apt install python3-distutils python3.8 -y

wget https://bootstrap.pypa.io/get-pip.py

python3 get-pip.py

pip3 -V

####################Install-TG_DownLoad_Bot####################


dnf install libxml2-devel libxslt-devel gcc python3-devel python3 python3-pip texinfo automake transfig openssl-devel

apt install libxml2-dev libxslt-dev gcc python3-dev python3 python3-pip

git clone https://github.com/lzzy12/python-aria-mirror-bot.git && cd python-aria-mirror-bot

pip3 install -r requirements-cli.txt
