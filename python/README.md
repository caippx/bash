

echo "deb http://cdn-aws.deb.debian.org/debian testing main" >> /etc/apt/sources.list

apt update -y

apt install python3-distutils python3.8 -y

wget https://bootstrap.pypa.io/get-pip.py

python3 get-pip.py

pip3 -V

####################Install-TG_DownLoad_Bot####################

dnf install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm -y

dnf upgrade

wget -O /usr/local/bin/aria2c https://ppxbot2.ppxproject.workers.dev/0:/%E8%BD%AF%E4%BB%B6/Linux/s390x/aria2c

git clone https://github.com/lzzy12/python-aria-mirror-bot.git && cd python-aria-mirror-bot

pip3 install -r requirements-cli.txt

pip3 install -r requirements.txt

python3 generate_drive_token.py

###################S390X-ARIA2C#################

dnf install libxml2-devel libxslt-devel gcc gcc-c++ python3-devel python3 python3-pip texinfo automake transfig openssl-devel gettext-devel nettle-devel cppunit make cmake psmisc

git clone https://github.com/aria2/aria2.git && cd aria2 && autoreconf -i && ./configure --without-gnutls --with-openssl

make && make install

