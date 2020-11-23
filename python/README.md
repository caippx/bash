

echo "deb http://cdn-aws.deb.debian.org/debian testing main" >> /etc/apt/sources.list

apt update -y

apt install python3-distutils python3.8 -y

wget https://bootstrap.pypa.io/get-pip.py

python3 get-pip.py

pip3 -V
