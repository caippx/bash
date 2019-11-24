#!/bin/bash
apt update -y
apt install unzip lrzsz python3-pip python3 locales -y
apt install language-pack-en -y
echo '
LANG=en_US.UTF-8
LANGUAGE=en_US:en
LC_ALL=
' > /etc/default/locale
source /etc/default/locale
wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
dpkg -i --force-depends google-chrome-stable_current_amd64.deb
apt install -f -y
LATEST=$(wget -q -O - http://chromedriver.storage.googleapis.com/LATEST_RELEASE)
wget http://chromedriver.storage.googleapis.com/$LATEST/chromedriver_linux64.zip
unzip chromedriver_linux64.zip
chmod 777 chromedriver
mv chromedriver /usr/bin/
echo 'export PATH=$PATH:/usr/bin/chromedriver' > .profile
source .profile
pip3 install selenium bs4 lxml requests
rm -rf *
