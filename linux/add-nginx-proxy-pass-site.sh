#!/usr/bin/env bash

site_domain=${1:-}
proxy_pass=${2:-}
https_port=${3:-443}

if [ -z "$site_domain" ] || [ -z "$proxy_pass" ]; then
    echo "缺少必要的参数，请使用 add-nginx-proxy-pass-site.sh site_domain proxy_pass 的方式传入必要参数"
    exit 1
fi

if [[ -f "/home/volume/nginx/site/$site_domain" ]]; then
    echo "$site_domain 的nginx配置已存在"
    exit 0
fi

bash <(curl -Ls https://raw.githubusercontent.com/tou13/somefiles/main/linux/add-diy-https-cert.sh)

cat <<EOF > /home/volume/nginx/site/$site_domain
server {
    listen $https_port ssl;
    listen [::]:$https_port ssl;
    server_name $site_domain;
    ssl_certificate       /home/volume/nginx/ssl/diy.crt;
    ssl_certificate_key   /home/volume/nginx/ssl/diy.key;
    ssl_protocols         TLSv1 TLSv1.1 TLSv1.2 TLSv1.3;
    ssl_ciphers           HIGH:!aNULL:!MD5;

    location / {
        proxy_pass $proxy_pass;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$http_host;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header Authorization \$http_authorization;
    }
}
EOF

echo "$site_domain 的nginx配置生成成功：/home/volume/nginx/site/$site_domain, 使用 https://$site_domain:$https_port 访问服务"