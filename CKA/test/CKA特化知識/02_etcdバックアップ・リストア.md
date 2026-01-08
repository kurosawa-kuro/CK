# CKA特化: etcdバックアップとリストア

## 概要

etcdはKubernetesクラスタの全状態を保存する**唯一の永続ストア**。
バックアップ・リストアは**CKA試験の最頻出問題**。

### 実技問題との対応

| 試験項目 | 使用する知識 |
|---------|------------|
| CKA試験 | etcdctl snapshot save/restore、証明書パス確認、マニフェスト編集 |

**注意**: kindクラスタではetcdに直接アクセスできないため、コマンド構築と理解確認が中心

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

```
pos/CK/CKA$   kind get clustersrs
  docker ps | grep cka
cka
3416a599e0d9   kindest/node:v1.27.3   "/usr/local/bin/entr…"   About an hour ago   Up About an hour   127.0.0.1:36483->6443/tcp   cka-control-plane
53cccfede788   kindest/node:v1.27.3   "/usr/local/bin/entr…"   About an hour ago   Up About an hour                               cka-worker
f8411532e3e4   kindest/node:v1.27.3   "/usr/local/bin/entr…"   About an hour ago   Up About an hour                               cka-worker2
ubuntu@DESKTOP-REF6HHU:~/repos/CK/CKA$   # Access the control plane container
  docker exec -it cka-control-plane cat /etc/kubernetes/manifests/etcd.yaml | grep -E "(cert|key|ca)"
    - --cert-file=/etc/kubernetes/pki/etcd/server.crt
    - --client-cert-auth=true
    - --key-file=/etc/kubernetes/pki/etcd/server.key
    - --peer-cert-file=/etc/kubernetes/pki/etcd/peer.crt
    - --peer-client-cert-auth=true
    - --peer-key-file=/etc/kubernetes/pki/etcd/peer.key
    - --peer-trusted-ca-file=/etc/kubernetes/pki/etcd/ca.crt
    - --trusted-ca-file=/etc/kubernetes/pki/etcd/ca.crt
      name: etcd-certs
  priorityClassName: system-node-critical
    name: etcd-certs
ubuntu@DESKTOP-REF6HHU:~/repos/CK/CKA$ 
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
kubectl describe pod etcd-cka-control-plane -n kube-system | grep -E "(cert|key|ca)"

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

---

## 段階的ハンズオン（実技問題への橋渡し）

### レベル1: 基礎（etcd確認とコマンド理解）

kindクラスタではetcdに直接アクセスできないため、docker exec経由で確認します。

#### 演習1-1: etcd Podの確認

```bash
# etcd Podの確認
kubectl get pods -n kube-system | grep etcd

# etcd Podの詳細
kubectl describe pod -n kube-system etcd-cka-control-plane | head -50
```

**確認ポイント:**
- etcdは静的Podとして動作
- コントロールプレーンノードで稼働

#### 演習1-2: etcd.yamlマニフェストの確認（kind環境）

```bash
# etcd.yamlの内容をdocker exec経由で確認
docker exec cka-control-plane cat /etc/kubernetes/manifests/etcd.yaml

# 証明書パスの抽出
docker exec cka-control-plane cat /etc/kubernetes/manifests/etcd.yaml | grep -E "(cert|key|ca)"
```

**出力例と読み方:**
```
--cert-file=/etc/kubernetes/pki/etcd/server.crt    ← --cert に使う
--key-file=/etc/kubernetes/pki/etcd/server.key     ← --key に使う
--trusted-ca-file=/etc/kubernetes/pki/etcd/ca.crt  ← --cacert に使う
```

#### 演習1-3: コマンドオプションの理解

以下の質問に答えてください:

1. `ETCDCTL_API=3` は何のため？
2. `--endpoints` には何を指定する？
3. `--cacert`, `--cert`, `--key` の違いは？

<details>
<summary>解答</summary>

1. **ETCDCTL_API=3**: etcdctl v3 APIを使用するため。v2とv3でコマンド形式が異なる
2. **--endpoints**: etcdサーバーのアドレス（通常 https://127.0.0.1:2379）
3. 証明書の種類:
   - `--cacert`: CA証明書（信頼の基点）
   - `--cert`: クライアント証明書（自分を証明）
   - `--key`: クライアント秘密鍵（認証用）

</details>

---

### レベル2: 応用（コマンド構築練習）

#### 演習2-1: バックアップコマンドの構築

etcd.yamlから証明書パスを確認し、バックアップコマンドを組み立てる練習です。

```bash
# Step 1: 証明書パスを確認
docker exec cka-control-plane cat /etc/kubernetes/manifests/etcd.yaml | grep -E "(-cert|-key|-ca)"

# Step 2: 以下のテンプレートを埋める
# ETCDCTL_API=3 etcdctl snapshot save /backup/snapshot.db \
#   --endpoints=https://127.0.0.1:2379 \
#   --cacert=__________  \
#   --cert=__________  \
#   --key=__________
```

<details>
<summary>解答</summary>

```bash
ETCDCTL_API=3 etcdctl snapshot save /backup/snapshot.db \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key
```

</details>

#### 演習2-2: リストアコマンドの構築

```bash
# リストアコマンドのテンプレートを埋める
# ETCDCTL_API=3 etcdctl snapshot restore /backup/snapshot.db \
#   --data-dir=__________
```

<details>
<summary>解答</summary>

```bash
ETCDCTL_API=3 etcdctl snapshot restore /backup/snapshot.db \
  --data-dir=/var/lib/etcd-restored
```

リストアには証明書オプションは不要（ローカルファイル操作のため）

</details>

#### 演習2-3: マニフェスト編集ポイントの理解

リストア後に編集が必要な箇所を確認:

```bash
# etcd.yamlの data-dir 関連箇所を確認
docker exec cka-control-plane cat /etc/kubernetes/manifests/etcd.yaml | grep -A 2 -B 2 "data-dir"
docker exec cka-control-plane cat /etc/kubernetes/manifests/etcd.yaml | grep -A 5 "hostPath"
```

**編集が必要な箇所:**
1. `--data-dir=/var/lib/etcd` → `/var/lib/etcd-restored`
2. `volumes.hostPath.path: /var/lib/etcd` → `/var/lib/etcd-restored`

---

### レベル3: 実技問題準備

#### 演習3-1: フルフロー理解確認

以下の手順を紙に書いてみてください:

1. バックアップの手順（3ステップ）
2. リストアの手順（4ステップ）

<details>
<summary>解答</summary>

**バックアップ手順:**
1. etcd.yamlから証明書パスを確認
2. etcdctl snapshot save コマンドを実行
3. snapshot status で確認

**リストア手順:**
1. etcdctl snapshot restore を新しいdata-dirに実行
2. etcd.yaml の --data-dir を変更
3. etcd.yaml の volumes.hostPath.path を変更
4. 保存してetcd再起動を待つ（kubeletが自動で再起動）

</details>

#### 演習3-2: コマンド書き取り練習

以下のコマンドを暗記用に3回書いてみてください:

```bash
# バックアップコマンド（書いてみる）




# リストアコマンド（書いてみる）



```

<details>
<summary>解答</summary>

```bash
# バックアップ
ETCDCTL_API=3 etcdctl snapshot save /backup/etcd-snapshot.db \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key

# リストア
ETCDCTL_API=3 etcdctl snapshot restore /backup/etcd-snapshot.db \
  --data-dir=/var/lib/etcd-restored
```

</details>

#### 演習3-3: トラブルシューティング理解

以下のエラーが出た場合の対処法を答えてください:

1. `Error: context deadline exceeded`
2. `Error: x509: certificate signed by unknown authority`
3. リストア後にAPI Serverが起動しない

<details>
<summary>解答</summary>

1. **context deadline exceeded**
   - 原因: endpointに到達できない
   - 対処: `--endpoints=https://127.0.0.1:2379` を確認（httpsを忘れない）

2. **x509: certificate signed by unknown authority**
   - 原因: 証明書パスが間違っている
   - 対処: etcd.yamlから正確なパスをコピー

3. **API Server起動しない**
   - 原因: data-dirのパスがマニフェストと一致していない
   - 対処:
     - `--data-dir` の値を確認
     - `volumes.hostPath.path` の値を確認
     - 両方を同じパスに設定

</details>

---

## チートシート

### 証明書パス確認

```bash
# etcd.yamlから証明書パスを抽出
cat /etc/kubernetes/manifests/etcd.yaml | grep -E "(cert|key|ca)"

# または kubectl describe で
kubectl describe pod -n kube-system etcd-<node-name> | grep -E "(cert|key|ca)"
```

### バックアップ（コピペ用）

```bash
ETCDCTL_API=3 etcdctl snapshot save /backup/etcd-snapshot.db \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key
```

### リストア（コピペ用）

```bash
ETCDCTL_API=3 etcdctl snapshot restore /backup/etcd-snapshot.db \
  --data-dir=/var/lib/etcd-restored
```

### スナップショット確認

```bash
ETCDCTL_API=3 etcdctl snapshot status /backup/etcd-snapshot.db --write-out=table
```

### マニフェスト編集箇所

```yaml
# /etc/kubernetes/manifests/etcd.yaml

# 1. data-dir を変更
- --data-dir=/var/lib/etcd-restored

# 2. volumes.hostPath.path を変更
volumes:
- hostPath:
    path: /var/lib/etcd-restored
```

### 証明書パス（デフォルト）

```
/etc/kubernetes/pki/etcd/
├── ca.crt          # --cacert
├── server.crt      # --cert
└── server.key      # --key
```

### 変数化テクニック（試験で便利）

```bash
# 証明書オプションを変数化
ETCD_OPTS="--endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key"

# 使用例
ETCDCTL_API=3 etcdctl $ETCD_OPTS snapshot save /backup/snap.db
ETCDCTL_API=3 etcdctl $ETCD_OPTS endpoint health
```

### エラー対処早見表

| エラー | 原因 | 対処 |
|-------|-----|------|
| context deadline exceeded | endpoint到達不可 | https://確認 |
| x509 certificate error | 証明書パス間違い | etcd.yamlからコピー |
| API Server起動しない | data-dir不一致 | マニフェスト2箇所確認 |
| etcdctl not found | etcdctlがない | apt install etcd-client |
