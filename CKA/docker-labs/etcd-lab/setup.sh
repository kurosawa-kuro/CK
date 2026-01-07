#!/bin/bash
# etcd演習環境セットアップスクリプト

set -e

echo "=== etcd演習環境を起動します ==="

# backupディレクトリ作成
mkdir -p backup

# Docker Compose起動
docker compose up -d

echo ""
echo "=== 起動完了 ==="
echo ""
echo "次のコマンドでetcd-clientに接続してください:"
echo "  docker exec -it cka-etcd-client /bin/sh"
echo ""
echo "README.mdの演習手順に従って練習してください。"
