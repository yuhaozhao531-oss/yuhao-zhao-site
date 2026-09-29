#!/usr/bin/env bash
# 一条命令同步两处线上站点：
#   1) GitHub Pages  https://yuhaozhao531-oss.github.io/yuhao-zhao-site/
#   2) 阿里云服务器  http://47.107.29.95:3002/ （pm2: yuhao-zhao-website，静态文件直接生效，无需重启）
# 用法：先 git commit，再运行 bash deploy.sh
set -e
cd "$(dirname "$0")"
REMOTE=ceolab
DIR=/opt/yuhao-zhao-website/public

# 服务器的 SSH 经常随机断开连接，所以每一步都自动重试
retry(){ for i in 1 2 3 4 5 6 7 8; do "$@" && return 0; echo "  连接被断开，第 $i 次重试..."; sleep 5; done; echo "失败：$*"; return 1; }

echo "[1/4] 推送到 GitHub Pages"
git -c http.sslBackend=openssl push   # Windows 默认的 schannel 偶尔握手失败

echo "[2/4] 备份服务器上的旧页面"
retry ssh -o ConnectTimeout=15 $REMOTE "cp $DIR/index.html $DIR/index.html.bak_\$(date +%Y%m%d%H%M)"

echo "[3/4] 上传页面和图片"
retry scp -q -o ConnectTimeout=15 index.html $REMOTE:$DIR/index.html
retry scp -q -o ConnectTimeout=15 uploads/* $REMOTE:$DIR/uploads/

echo "[4/4] 检查线上版本"
local_md5=$(md5sum index.html | cut -d' ' -f1)
remote_md5=$(curl -s -m 20 http://47.107.29.95:3002/ | md5sum | cut -d' ' -f1)
[ "$local_md5" = "$remote_md5" ] && echo "服务器已同步 ✓" || echo "服务器内容和本地不一致，请检查"
echo "GitHub Pages 约 1 分钟后生效"
