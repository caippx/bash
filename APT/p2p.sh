#!/bin/bash
wget https://raw.githubusercontent.com/caippx/bash/master/APT/p2pclient
chmod +x p2pclient
nohup ./p2pclient -l admin@ppxwo.com  >> /tmp/p2pclient.log 2>&1 &
