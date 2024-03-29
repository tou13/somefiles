#!/usr/bin/env bash

if command -v ninja &> /dev/null; then
    echo "ninja 已安装，在线更新使用 ninja update 命令"
    exit 0
fi

ninja_port=${1:-7999}
password=$(openssl rand -hex 16)

wget -O ninja.tar.gz https://github.com/gngpp/ninja/releases/download/v0.9.36/ninja-0.9.36-x86_64-unknown-linux-musl.tar.gz
tar -xvzf ninja.tar.gz
mv ./ninja /usr/local/bin/

cat <<EOF > /etc/systemd/system/ninja.service
[Unit]
Description=Reverse engineered ChatGPT proxy
Documentation=https://github.com/gngpp/ninja/blob/main/README_zh.md
After=network.target

[Service]
ExecStart=/usr/local/bin/ninja run --bind 0.0.0.0:$ninja_port --auth-key=$password
Restart=on-failure
Environment="HOME=/root"

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload

systemctl enable --now ninja
systemctl status ninja

echo "ninja安装成功，使用密码 $password 登录 http://host:$ninja_port/fingerprint/upload 上传har文件后使用。" 
echo "har文件需要使用浏览器控制台，再网络选项卡中过滤 https://tcr9i.chat.openai.com/fc/gt2/public_key/35536E1E-65B4-4D96-9D97-6ADB7EFF8147 的请求，右击保存为har文件上传"