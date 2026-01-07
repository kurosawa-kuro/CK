# etcd バックアップ・リストア演習

CKA試験で必出の etcd バックアップ・リストアを Docker で体験できる環境です。

> **注意**: 本番のCKA試験ではkubeadmクラスタのetcdを操作しますが、
> kindでは直接etcdにアクセスできないため、この模擬環境で練習します。

---

## 環境起動

```bash
cd /home/ubuntu/repos/CK/CKA/docker-labs/etcd-lab
docker compose up -d
```

**確認:**
```bash
docker compose ps
```

```
NAME              STATUS    PORTS
cka-etcd          running   0.0.0.0:2379->2379/tcp
cka-etcd-client   running
```

---

## 演習1: etcdへのデータ登録

### Step 1: etcd-clientコンテナに接続

```bash
docker exec -it cka-etcd-client /bin/sh
```

### Step 2: データを登録

```bash
# 環境変数確認
echo $ETCDCTL_API
echo $ETCDCTL_ENDPOINTS

# データ登録
etcdctl put /registry/configmaps/default/my-config '{"data":{"key1":"value1"}}'
etcdctl put /registry/secrets/default/my-secret '{"data":{"password":"secret123"}}'
etcdctl put /registry/pods/default/nginx '{"metadata":{"name":"nginx"}}'

# 確認
etcdctl get /registry --prefix --keys-only
```

**出力例:**
```
/registry/configmaps/default/my-config
/registry/pods/default/nginx
/registry/secrets/default/my-secret
```

---

## 演習2: etcd スナップショット（バックアップ）

### CKA試験での典型的な問題

> etcdデータベースのスナップショットを `/backup/etcd-snapshot.db` に保存してください。

### 解答

```bash
# etcd-client コンテナ内で実行
etcdctl snapshot save /backup/etcd-snapshot.db

# スナップショット確認
etcdctl snapshot status /backup/etcd-snapshot.db --write-out=table
```

**出力例:**
```
+----------+----------+------------+------------+
|   HASH   | REVISION | TOTAL KEYS | TOTAL SIZE |
+----------+----------+------------+------------+
| 3d1b3c9a |        5 |         10 |      25 kB |
+----------+----------+------------+------------+
```

### なぜ?
- `snapshot save`: etcdのデータを単一ファイルにダンプ
- バックアップファイルはクラスタ外に保存可能

---

## 演習3: データ変更（バックアップ検証用）

### バックアップ後にデータを変更

```bash
# 既存データ削除
etcdctl del /registry/pods/default/nginx

# 新しいデータ追加
etcdctl put /registry/pods/default/new-pod '{"metadata":{"name":"new-pod"}}'

# 確認（nginx が消え、new-pod が追加）
etcdctl get /registry --prefix --keys-only
```

---

## 演習4: etcd リストア

### CKA試験での典型的な問題

> `/backup/etcd-snapshot.db` からetcdデータをリストアしてください。
> リストア先ディレクトリは `/etcd-data-restored` とします。

### 解答

```bash
# リストア実行
etcdctl snapshot restore /backup/etcd-snapshot.db \
  --data-dir=/backup/etcd-data-restored

# リストアされたデータ確認
ls -la /backup/etcd-data-restored/
```

**出力例:**
```
total 12
drwx------ 3 root root 4096 Jan  1 00:00 .
drwxr-xr-x 3 root root 4096 Jan  1 00:00 ..
drwx------ 4 root root 4096 Jan  1 00:00 member
```

### なぜ?
- `snapshot restore`: スナップショットから新しいデータディレクトリを作成
- 本番では `--data-dir` を新しい場所に指定し、etcdの起動設定を変更する

---

## 演習5: 本番環境でのリストア手順（解説）

実際のkubeadmクラスタでは以下の手順になります：

### 1. etcd Podを停止
```bash
# control-planeノードで実行
sudo mv /etc/kubernetes/manifests/etcd.yaml /tmp/
```

### 2. スナップショットをリストア
```bash
ETCDCTL_API=3 etcdctl snapshot restore /backup/etcd-snapshot.db \
  --data-dir=/var/lib/etcd-restored \
  --name=<etcd-node-name> \
  --initial-cluster=<etcd-node-name>=https://127.0.0.1:2380 \
  --initial-advertise-peer-urls=https://127.0.0.1:2380
```

### 3. etcd.yamlのdata-dirを変更
```yaml
# /tmp/etcd.yaml を編集
volumes:
- hostPath:
    path: /var/lib/etcd-restored  # 変更
    type: DirectoryOrCreate
  name: etcd-data
```

### 4. etcd Podを再起動
```bash
sudo mv /tmp/etcd.yaml /etc/kubernetes/manifests/
```

---

## CKA試験での証明書パス（暗記必須）

kubeadmクラスタでは TLS が有効なため、証明書を指定する必要があります：

```bash
ETCDCTL_API=3 etcdctl snapshot save /backup/snapshot.db \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key
```

### 証明書パスの覚え方
```
/etc/kubernetes/pki/etcd/
├── ca.crt          # --cacert
├── server.crt      # --cert
└── server.key      # --key
```

---

## クリーンアップ

```bash
# コンテナから抜ける
exit

# 環境停止
docker compose down -v

# バックアップファイル削除
rm -rf backup/*
```

---

## よくあるミス

| ミス | 症状 | 対処法 |
|-----|-----|-------|
| ETCDCTL_API未設定 | v2 APIが使われる | `export ETCDCTL_API=3` |
| 証明書パス間違い | connection refused | `/etc/kubernetes/pki/etcd/` を確認 |
| endpoints未指定 | localhost:2379に接続 | `--endpoints=https://127.0.0.1:2379` |
| restore後にdata-dir未変更 | 古いデータのまま | etcd.yamlのhostPathを変更 |

---

## 関連ドキュメント

- [02_etcdバックアップ・リストア.md](../../test/CKA特化知識/02_etcdバックアップ・リストア.md)
