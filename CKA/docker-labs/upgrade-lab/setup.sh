#!/bin/bash
# クラスタアップグレード演習環境セットアップスクリプト

set -e

echo "=== クラスタアップグレード演習環境を起動します ==="

# ディレクトリ作成
mkdir -p scripts manifests

# Docker Compose起動
docker compose up -d

echo ""
echo "=== 起動完了 ==="
echo ""
echo "この演習はコマンド学習用です。"
echo "README.mdを参照してアップグレード手順を学習してください。"
echo ""
echo "コンテナに接続する場合:"
echo "  docker exec -it cka-upgrade-sim /bin/bash"
