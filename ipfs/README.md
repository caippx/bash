#测试一下

wget https://github.com/ipfs/go-ipfs/releases/download/v0.9.0-rc2/go-ipfs_v0.9.0-rc2_linux-amd64.tar.gz && tar -zxvf go-ipfs_v0.9.0-rc2_linux-amd64.tar.gz && cd go-ipfs<br>
bash install.sh && ipfs version && cd ~ && ipfs init<br>
ipfs config Addresses.API /ip4/0.0.0.0/tcp/5001<br>
ipfs config Addresses.Gateway /ip4/0.0.0.0/tcp/8080<br>
ipfs config --json API.HTTPHeaders.Access-Control-Allow-Origin '["*"]'<br>
ipfs config --json API.HTTPHeaders.Access-Control-Allow-Methods '["GET", "POST"]'<br>
ipfs config --json API.HTTPHeaders.Access-Control-Allow-Headers '["Authorization"]'<br>
ipfs config --json API.HTTPHeaders.Access-Control-Expose-Headers '["Location"]'<br>
ipfs config --json API.HTTPHeaders.Access-Control-Allow-Credentials '["true"]'<br>
nohup ipfs daemon &<br>
