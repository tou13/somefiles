#!/usr/bin/env bash

output_message=$(bash <(curl -Ls https://raw.githubusercontent.com/tou13/somefiles/main/common/docker-init-check.sh))
if [ "$?" -ne 0 ]; then
    echo "初始化脚本检查失败，错误原因：$output_message"
    exit $?
fi

login_pass=${1:-pass@word}
web_port=${2:-6901}

if [ -d "/home/volume/ubuntu/config" ]; then
    read -p "Ubuntu配置已经存在，是否继续安装？(y/n): " user_input

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

mkdir -p /home/volume/ubuntu/config
mkdir -p /home/volume/ubuntu/local
mkdir -p /home/volume/ubuntu/uploads
mkdir -p /home/volume/ubuntu/vnc
cat <<EOF > /home/volume/ubuntu/vnc/kasmvnc.yaml
logging:
  log_writer_name: all
  log_dest: logfile
  level: 100

user_session:
  session_type: exclusive
  new_session_disconnects_existing_exclusive_session: true
EOF

chown -R 1000:1000 /home/volume/ubuntu

mkdir -p /home/download/ubuntu
chown -R 1000:1000 /home/download

docker stop ubuntu-$USER && docker rm ubuntu-$USER

docker run -d \
  --name ubuntu-$USER \
  --restart unless-stopped \
  --shm-size 1000m \
  --network internalnet \
  --dns 94.140.14.14 \
  --dns 94.140.14.15 \
  -e LANG=zh_CN.UTF-8 \
  -e LANGUAGE=zh_CN:zh \
  -e LC_ALL=zh_CN.UTF-8 \
  -e TZ=Asia/Shanghai \
  -e HTTP_PROXY= \
  -e HTTPS_PROXY= \
  -e http_proxy= \
  -e https_proxy= \
  -e VNC_PW=$login_pass \
  -p $web_port:6901 \
  -v /home/volume/ubuntu/vnc:/home/kasm-user/.vnc \
  -v /home/volume/ubuntu/config:/home/kasm-user/.config \
  -v /home/volume/ubuntu/local:/home/kasm-user/.local \
  -v /home/volume/ubuntu/uploads:/home/kasm-user/Uploads \
  -v /home/download/ubuntu:/home/kasm-user/Downloads \
  kasmweb/ubuntu-jammy-desktop:1.14.0

echo "Ubuntu安装成功，访问 https://host:$web_port ，使用账号 kasm_user / $login_pass 登入。使用nginx反代的配置示例如下："
cat <<EOF
server {
    listen 443 ssl;
    listen [::]:443 ssl;
    server_name yourdomain.com;
    ssl_certificate       /home/volume/nginx/ssl/diy.crt;
    ssl_certificate_key   /home/volume/nginx/ssl/diy.key;

    location / {
        proxy_pass https://127.0.0.1:$web_port/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Authorization \$http_authorization;
    }
}
EOF