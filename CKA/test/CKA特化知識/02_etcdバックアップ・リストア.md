# CKA特化: etcdバックアップとリストア

## 概要

etcdはKubernetesクラスタの全状態を保存する**唯一の永続ストア**。
バックアップ・リストアは**CKA試験の最頻出問題**。

---

## 必須環境変数

```bash
# API バージョン指定（必須！）
export ETCDCTL_API=3

# これがないとv2 APIが使われてエラーになる
```

---

## 証明書の場所を確認

```bash
# etcdのマニフェストから確認
cat /etc/kubernetes/manifests/etcd.yaml | grep -E "(cert|key|ca)"

# 通常の場所
--cert-file=/etc/kubernetes/pki/etcd/server.crt
--key-file=/etc/kubernetes/pki/etcd/server.key
--trusted-ca-file=/etc/kubernetes/pki/etcd/ca.crt
```

---

## バックアップ（snapshot save）

### 基本コマンド（暗記必須）

```bash
ETCDCTL_API=3 etcdctl snapshot save /backup/snapshot.db \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key
```

### 各オプションの意味

| オプション | 説明 | 試験での値 |
|-----------|------|-----------|
| `--endpoints` | etcdのエンドポイント | https://127.0.0.1:2379 |
| `--cacert` | CA証明書 | /etc/kubernetes/pki/etcd/ca.crt |
| `--cert` | クライアント証明書 | /etc/kubernetes/pki/etcd/server.crt |
| `--key` | 秘密鍵 | /etc/kubernetes/pki/etcd/server.key |

### バックアップ確認

```bash
# スナップショットの状態確認
ETCDCTL_API=3 etcdctl snapshot status /backup/snapshot.db --write-out=table
```

---

## リストア（snapshot restore）

### 基本コマンド（暗記必須）

```bash
ETCDCTL_API=3 etcdctl snapshot restore /backup/snapshot.db \
  --data-dir=/var/lib/etcd-restored
```

### リストア後の手順

```bash
# 1. etcdのマニフェストを編集
vi /etc/kubernetes/manifests/etcd.yaml

# 2. data-dirを変更
# 変更前
- --data-dir=/var/lib/etcd
# 変更後
- --data-dir=/var/lib/etcd-restored

# 3. volumeのhostPathも変更
volumes:
- hostPath:
    path: /var/lib/etcd-restored  # ここを変更
    type: DirectoryOrCreate
  name: etcd-data

# 4. 保存するとkubeletが自動的にetcdを再起動
```

---

## 試験での手順まとめ

### Step 1: 現在の設定を確認

```bash
# etcdのPod情報から証明書パスを取得
kubectl describe pod etcd-controlplane -n kube-system | grep -E "(cert|key|ca)"

# または直接マニフェストを確認
cat /etc/kubernetes/manifests/etcd.yaml
```

### Step 2: バックアップ実行

```bash
ETCDCTL_API=3 etcdctl snapshot save /tmp/etcd-backup.db \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key
```

### Step 3: リストア実行

```bash
# 新しいディレクトリにリストア
ETCDCTL_API=3 etcdctl snapshot restore /tmp/etcd-backup.db \
  --data-dir=/var/lib/etcd-new
```

### Step 4: etcd設定を更新

```bash
# マニフェストのdata-dirを更新
vi /etc/kubernetes/manifests/etcd.yaml

# 変更箇所:
# 1. --data-dir=/var/lib/etcd-new
# 2. volumes.hostPath.path=/var/lib/etcd-new
```

### Step 5: 確認

```bash
# etcdが再起動するまで待つ（1-2分）
kubectl get pods -n kube-system | grep etcd

# クラスタ状態確認
kubectl get nodes
kubectl get pods -A
```

---

## よくあるエラーと対処

### エラー1: Error: context deadline exceeded

```bash
# 原因: エンドポイントに到達できない
# 対処: エンドポイントのURLを確認
--endpoints=https://127.0.0.1:2379  # httpsを忘れない
```

### エラー2: Error: x509: certificate signed by unknown authority

```bash
# 原因: 証明書のパスが間違っている
# 対処: etcd.yamlから正確なパスをコピー
cat /etc/kubernetes/manifests/etcd.yaml | grep -E "cert|key|ca"
```

### エラー3: リストア後にAPIサーバーが起動しない

```bash
# 原因: data-dirのパスがマニフェストと一致していない
# 対処: 以下の2箇所を確認
# 1. --data-dir の値
# 2. volumes.hostPath.path の値
```

---

## 試験Tips

### 時間短縮テクニック

```bash
# エイリアス設定
alias etcdctl='ETCDCTL_API=3 etcdctl'

# 証明書オプションをまとめて変数化
ETCD_OPTS="--endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key"

# 使用例
etcdctl $ETCD_OPTS snapshot save /backup/snap.db
```

### 暗記すべき証明書パス

```
/etc/kubernetes/pki/etcd/
├── ca.crt          # --cacert
├── server.crt      # --cert
└── server.key      # --key
```

---

## 外部etcd（Stacked vs External）

### Stacked etcd（デフォルト）
- コントロールプレーンノード上でetcdが動作
- `/etc/kubernetes/manifests/etcd.yaml` で管理

### External etcd
- 別サーバーでetcdが動作
- エンドポイントが異なる

```bash
# 外部etcdの場合
--endpoints=https://<etcd-server-ip>:2379

# 証明書パスも異なる可能性あり
# 必ず問題文で確認すること
```

---

## クイックリファレンス

```bash
# バックアップ（コピペ用）
ETCDCTL_API=3 etcdctl snapshot save /backup/etcd-snapshot.db \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key

# リストア（コピペ用）
ETCDCTL_API=3 etcdctl snapshot restore /backup/etcd-snapshot.db \
  --data-dir=/var/lib/etcd-restored

# 確認
ETCDCTL_API=3 etcdctl snapshot status /backup/etcd-snapshot.db
```

---

## ミニ演習（Docker模擬環境）

kindではetcdに直接アクセスできないため、Docker模擬環境で練習します。

### 環境起動

```bash
cd /home/ubuntu/repos/CK/CKA/docker-labs/etcd-lab
./setup.sh
```

### 演習1: etcdへのデータ登録

```bash
# etcd-clientコンテナに接続
docker exec -it cka-etcd-client /bin/sh

# データ登録
etcdctl put /test/key1 "value1"
etcdctl put /test/key2 "value2"

# 確認
etcdctl get /test --prefix
```

### 演習2: スナップショット保存

```bash
# バックアップ
etcdctl snapshot save /backup/etcd-snapshot.db

# 確認
etcdctl snapshot status /backup/etcd-snapshot.db --write-out=table
```

### 演習3: データ変更とリストア

```bash
# データ削除
etcdctl del /test/key1

# 確認（key1が消えている）
etcdctl get /test --prefix

# リストア
etcdctl snapshot restore /backup/etcd-snapshot.db --data-dir=/backup/restored

# リストアされたデータ確認
ls /backup/restored/
```

### クリーンアップ

```bash
exit
docker compose down -v
```

詳細な演習手順は [docker-labs/etcd-lab/README.md](../../docker-labs/etcd-lab/README.md) を参照
