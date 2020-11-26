# bash
一些自己写（chao）的jio本

<p>
  DeBian 10国内源<br>
deb http://mirrors.aliyun.com/debian/ buster main non-free contrib <br>
deb http://mirrors.aliyun.com/debian-security buster/updates main<br>
deb http://mirrors.aliyun.com/debian/ buster-updates main non-free contrib<br>
deb http://mirrors.aliyun.com/debian/ buster-backports main non-free contrib<br>
<br>
deb-src http://mirrors.aliyun.com/debian-security buster/updates main<br>
deb-src http://mirrors.aliyun.com/debian/ buster main non-free contrib<br>
deb-src http://mirrors.aliyun.com/debian/ buster-updates main non-free contrib<br>
deb-src http://mirrors.aliyun.com/debian/ buster-backports main non-free contrib<br>
</p>

<p>
  GOlang 和 nodejs<br>
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.3/install.sh | bash<br>
nvm install 12.18.0<br>
  #国内源:<br>
  #export NVM_NODEJS_ORG_MIRROR=https://npm.taobao.org/mirrors/node <br>
  #npm config set registry http://registry.npm.taobao.org<br>
 <br>
curl -SL https://gitee.com/skiy/golang-install/raw/master/install.sh | bash /dev/stdin -v 1.13.6<br>
set GOOS=linux<br>
set GOARCH=s390x<br>
  </p>
