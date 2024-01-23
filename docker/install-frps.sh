#!/usr/bin/env bash

if ! command -v docker &> /dev/null; then
    echo "请先安装docker。"
    exit 1
fi

if [ -f "/home/volume/frp/config/frps.ini" ]; then
    echo "FRP服务端配置已存在于 /home/volume/frp/config/frps.ini ，跳过安装"
    exit 0
fi

server_token=${1:-pass@word}

mkdir -p /home/volume/frp/config

cat <<EOF > /home/volume/frp/config/frps.ini
[common]
bind_port = 22150
kcp_bind_port = 22150
tls_enable = true
token = $server_token
allow_ports = 22151-22159
EOF

chown -R 1000:1000 /home/volume/frp

docker run -d \
  --name frps-$USER \
  --restart unless-stopped \
  --cpus 0.12 \
  --memory 256M \
  --network internalnet \
  -p 22150-22159:22150-22159 \
  -v /home/volume/frp/config/frps.ini:/frp/frps.ini \
  stilleshan/frps:0.51.3

echo "FRP服务端运行成功。客户端配置示例如下："
cat << EOF
[common]
server_addr = 服务器公网IP
server_port = 22150
tls_enable = true
token = $server_token

[ssh]
type = tcp
local_ip = 127.0.0.1
local_port = 22
remote_port = 22151
use_compression = true
EOF