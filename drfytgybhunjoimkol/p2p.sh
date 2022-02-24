#!/bin/bash
wget https://updates.peer2profit.com/p2pclient_0.56_amd64.deb
dpkg -i p2pclient_0.56_amd64.deb
nohup p2pclient --login "admin@ppxwo.com" 2>1 &
