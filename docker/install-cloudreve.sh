#!/usr/bin/env bash

output_message=$(bash <(curl -Ls https://raw.githubusercontent.com/tou13/somefiles/main/common/docker-init-check.sh))
if [ "$?" -ne 0 ]; then
    echo "初始化脚本检查失败，错误原因：$output_message"
    exit $?
fi

if [ -f "/home/volume/cloudreve/config/conf.ini" ]; then
    read -p "cloudreve配置已存在于 /home/volume/cloudreve/config/conf.ini ，是否继续安装？(y/n): " user_input

    if [ "$user_input" = "n" ]; then
        echo "安装被用户取消"
        exit 0
    elif [ "$user_input" = "y" ]; then
        echo "继续安装..."
    else
        echo "无效输入，安装被取消"
        exit 1
    fi
fi

mkdir -p /home/volume/cloudreve/config
mkdir -p /home/volume/cloudreve/db

if [ ! -f "/home/volume/cloudreve/config/conf.ini" ]; then
    cat <<EOF > /home/volume/cloudreve/config/conf.ini
[Database]
DBFile = /cloudreve/db/cloudreve.db
EOF
fi

chown -R 1000:1000 /home/volume/cloudreve

docker run -d \
  --name cloudreve-$USER \
  --restart unless-stopped \
  --cpus 0.5 \
  --memory 512M \
  --network internalnet \
  -u 1000:1000 \
  -e PUID=1000 \
  -e PGID=1000 \
  -e TZ=Asia/Shanghai \
  -p 5212:5212 \
  -v /home/volume/cloudreve/uploads:/cloudreve/uploads \
  -v /home/volume/cloudreve/avatar:/cloudreve/avatar \
  -v /home/volume/cloudreve/config:/cloudreve/config \
  -v /home/volume/cloudreve/db:/cloudreve/db \
  xavierniu/cloudreve:3.5.1

echo "cloudreve运行成功，请使用 http://host:5212 访问"