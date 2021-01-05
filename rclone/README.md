#!/bin/bash

#install zip unzip first 
#apt install fuse zip unzip screen -y
#安装
curl https://rclone.org/install.sh | sudo bash

#挂载
rclone mount DriveName:Folder LocalFolder --copy-links --no-gzip-encoding --no-check-certificate --allow-other --allow-non-empty --umask 000 --vfs-cache-mode writes

rclone mount kanpian: /kanpian  --umask 0000 --default-permissions --allow-other --transfers 10 --buffer-size 32M --low-level-retries 200 --dir-cache-time 12h --vfs-read-chunk-size 32M --vfs-read-chunk-size-limit 1G --copy-links --no-gzip-encoding --no-check-certificate --vfs-cache-mode writes

#取消挂载
fusermount -qzu LocalFolder


#其他参数

#该参数主要是上传用的
rclone mount DriveName:Folder LocalFolder \
 --umask 0000 \
 --default-permissions \
 --allow-non-empty \
 --allow-other \
 --transfers 4 \
 --buffer-size 32M \
 --low-level-retries 200

#如果你还涉及到读取使用，比如使用H5ai等在线播放，就还建议加3个参数，添加格式参考上面
--dir-cache-time 12h
--vfs-read-chunk-size 32M
--vfs-read-chunk-size-limit 1G
