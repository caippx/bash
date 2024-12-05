#!/bin/bash

apk add git e2fsprogs e2fsprogs-extra
apk add build-base
apk add libc-dev 
wget https://go.dev/dl/go1.23.3.linux-amd64.tar.gz && tar -C /usr/local -xzf go1.23.3.linux-amd64.tar.gz
export PATH=$PATH:/usr/local/go/bin
go version

git clone https://github.com/MHSanaei/3x-ui && cd 3x-ui
go build
