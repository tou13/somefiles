#!/usr/bin/env bash

output_message=$(bash <(curl -Ls https://raw.githubusercontent.com/tou13/somefiles/main/common/docker-init-check.sh))
if [ "$?" -ne 0 ]; then
    echo "初始化脚本检查失败，错误原因：$output_message"
    exit $?
fi

my_domain=${1:-example.com}
cf_token=${2:-}
cf_id=${3:-}

if [ -z "$cf_token" ] || [ -z "$cf_id" ] || [ -z "$my_domain" ]; then
    echo "缺少参数，正确命令形式为：add-https-cert.sh 域名 CF_TOKEN CF_ACCOUNT_ID"
    exit 1
fi

docker run --rm -it -v "$(pwd)/ssl-certs":/acme.sh \
    -e CF_Token="$cf_token" -e CF_Account_ID="$cf_id" \
    --net=host neilpang/acme.sh \
    --issue \
    --dns dns_cf \
    --server letsencrypt \
    -d $my_domain -d *.$my_domain \
    --keylength 2048

docker run --rm -it -v "$(pwd)/ssl-certs":/acme.sh \
    -v /home/volume/nginx/ssl:/nginxssl \
    --net=host neilpang/acme.sh \
    --install-cert -d $my_domain \
    --key-file /nginxssl/$my_domain.key \
    --fullchain-file /nginxssl/$my_domain.crt

chown -R 1000:1000 /home/volume/nginx/ssl

echo "域名 $my_domain 的https证书生成成功，位于 /home/volume/nginx/ssl/$my_domain.key 和 /home/volume/nginx/ssl/$my_domain.crt，请重启对应服务以生效"