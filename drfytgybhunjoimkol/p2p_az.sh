#!/bin/bash
wget https://updates.peer2profit.com/p2pclient_0.56_amd64.deb
dpkg -i p2pclient_0.56_amd64.deb
nohup p2pclient --login admin@ppxwo.com -n 10.0.0.4;8.8.8.8" 2>1 &
