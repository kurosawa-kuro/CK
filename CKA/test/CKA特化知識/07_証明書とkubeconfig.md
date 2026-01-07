# CKA特化: 証明書と kubeconfig

## 概要

Kubernetesは**TLS証明書**による相互認証を使用。
証明書の管理とkubeconfigの理解はCKA必須スキル。

---

## Kubernetes PKI 構造

```
/etc/kubernetes/pki/
├── ca.crt                    # Kubernetes CA
├── ca.key
├── apiserver.crt             # API Server
├── apiserver.key
├── apiserver-kubelet-client.crt
├── apiserver-kubelet-client.key
├── apiserver-etcd-client.crt
├── apiserver-etcd-client.key
├── front-proxy-ca.crt
├── front-proxy-ca.key
├── front-proxy-client.crt
├── front-proxy-client.key
├── sa.key                    # ServiceAccount
├── sa.pub
└── etcd/
    ├── ca.crt                # etcd CA
    ├── ca.key
    ├── server.crt
    ├── server.key
    ├── peer.crt
    ├── peer.key
    ├── healthcheck-client.crt
    └── healthcheck-client.key
```

---

## 証明書の役割

| 証明書 | 用途 |
|-------|------|
| ca.crt/key | クラスタのルートCA |
| apiserver.crt | API Serverのサーバー証明書 |
| apiserver-kubelet-client | API Server → kubelet 通信 |
| apiserver-etcd-client | API Server → etcd 通信 |
| etcd/ca.crt | etcdのルートCA |
| etcd/server.crt | etcdのサーバー証明書 |

---

## 証明書の確認

### kubeadm で確認（推奨）

```bash
# 全証明書の有効期限を確認
kubeadm certs check-expiration

# 出力例
CERTIFICATE                EXPIRES                  RESIDUAL TIME
admin.conf                 Jan 01, 2026 00:00 UTC   364d
apiserver                  Jan 01, 2026 00:00 UTC   364d
...
```

### openssl で確認

```bash
# 証明書の詳細確認
openssl x509 -in /etc/kubernetes/pki/apiserver.crt -noout -text

# 有効期限のみ
openssl x509 -in /etc/kubernetes/pki/apiserver.crt -noout -dates

# Subject と Issuer
openssl x509 -in /etc/kubernetes/pki/apiserver.crt -noout -subject -issuer
```

---

## 証明書の更新

### kubeadm による更新

```bash
# 全証明書を更新
kubeadm certs renew all

# 個別に更新
kubeadm certs renew apiserver
kubeadm certs renew apiserver-kubelet-client
kubeadm certs renew admin.conf

# 更新後、コントロールプレーンを再起動
# (静的Podは自動的に再起動されるが、念のため確認)
kubectl get pods -n kube-system
```

---

## kubeconfig の構造

```yaml
apiVersion: v1
kind: Config
clusters:
- cluster:
    certificate-authority-data: <base64 encoded CA>
    server: https://192.168.1.100:6443
  name: kubernetes
contexts:
- context:
    cluster: kubernetes
    user: kubernetes-admin
    namespace: default    # オプション
  name: kubernetes-admin@kubernetes
current-context: kubernetes-admin@kubernetes
users:
- name: kubernetes-admin
  user:
    client-certificate-data: <base64 encoded cert>
    client-key-data: <base64 encoded key>
```

### 3つの主要セクション

| セクション | 内容 |
|-----------|------|
| clusters | クラスタのAPI Server URLとCA |
| users | ユーザーの認証情報（証明書/トークン） |
| contexts | cluster + user + namespace の組み合わせ |

---

## kubeconfig の操作

### 現在の設定確認

```bash
# 現在のコンテキスト
kubectl config current-context

# 全コンテキスト一覧
kubectl config get-contexts

# 設定全体を表示
kubectl config view

# 特定のkubeconfigを使用
kubectl config view --kubeconfig=/path/to/config
```

### コンテキストの切り替え

```bash
# コンテキストを切り替え
kubectl config use-context <context-name>

# 例
kubectl config use-context kubernetes-admin@kubernetes
```

### コンテキストの作成

```bash
# クラスタを追加
kubectl config set-cluster my-cluster \
  --server=https://192.168.1.100:6443 \
  --certificate-authority=/path/to/ca.crt

# ユーザーを追加（証明書認証）
kubectl config set-credentials my-user \
  --client-certificate=/path/to/user.crt \
  --client-key=/path/to/user.key

# ユーザーを追加（トークン認証）
kubectl config set-credentials my-user \
  --token=<token>

# コンテキストを作成
kubectl config set-context my-context \
  --cluster=my-cluster \
  --user=my-user \
  --namespace=my-namespace
```

---

## 新規ユーザーの作成（証明書署名要求）

### Step 1: 秘密鍵と CSR を作成

```bash
# 秘密鍵を生成
openssl genrsa -out jane.key 2048

# CSR を生成
openssl req -new -key jane.key -out jane.csr -subj "/CN=jane/O=developers"
```

### Step 2: CertificateSigningRequest を作成

```bash
# CSR を base64 エンコード
cat jane.csr | base64 | tr -d '\n'
```

```yaml
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: jane
spec:
  request: <base64-encoded-csr>
  signerName: kubernetes.io/kube-apiserver-client
  usages:
  - client auth
```

### Step 3: CSR を承認

```bash
# CSR 一覧
kubectl get csr

# 承認
kubectl certificate approve jane

# 証明書を取得
kubectl get csr jane -o jsonpath='{.status.certificate}' | base64 -d > jane.crt
```

### Step 4: kubeconfig に追加

```bash
# ユーザーを追加
kubectl config set-credentials jane \
  --client-certificate=jane.crt \
  --client-key=jane.key

# コンテキストを作成
kubectl config set-context jane-context \
  --cluster=kubernetes \
  --user=jane
```

---

## kubeconfig のデフォルト場所

```bash
# デフォルト
~/.kube/config

# 環境変数で上書き
export KUBECONFIG=/path/to/config

# 複数ファイルをマージ
export KUBECONFIG=/path/to/config1:/path/to/config2
```

---

## 試験頻出パターン

### パターン1: 証明書の有効期限確認

```bash
# 問題: apiserver の証明書有効期限を確認

kubeadm certs check-expiration
# または
openssl x509 -in /etc/kubernetes/pki/apiserver.crt -noout -dates
```

### パターン2: コンテキスト切り替え

```bash
# 問題: my-context に切り替え

kubectl config use-context my-context
kubectl config current-context  # 確認
```

### パターン3: 新規ユーザー用 kubeconfig 作成

```bash
# 問題: jane 用の kubeconfig を /home/jane/.kube/config に作成

# 1. 証明書がある前提で
kubectl config set-cluster kubernetes \
  --server=https://192.168.1.100:6443 \
  --certificate-authority=/etc/kubernetes/pki/ca.crt \
  --kubeconfig=/home/jane/.kube/config

kubectl config set-credentials jane \
  --client-certificate=/path/to/jane.crt \
  --client-key=/path/to/jane.key \
  --kubeconfig=/home/jane/.kube/config

kubectl config set-context jane@kubernetes \
  --cluster=kubernetes \
  --user=jane \
  --kubeconfig=/home/jane/.kube/config

kubectl config use-context jane@kubernetes \
  --kubeconfig=/home/jane/.kube/config
```

---

## CSR の承認/拒否

```bash
# CSR 一覧
kubectl get csr

# 承認
kubectl certificate approve <csr-name>

# 拒否
kubectl certificate deny <csr-name>

# 削除
kubectl delete csr <csr-name>
```

---

## よくある証明書エラー

| エラー | 原因 | 対処 |
|-------|------|------|
| x509: certificate expired | 証明書期限切れ | kubeadm certs renew |
| x509: certificate signed by unknown authority | CA不一致 | 正しいCAを指定 |
| Unable to connect to the server | 証明書パス間違い | パスを確認 |

---

## クイックリファレンス

```bash
# 証明書確認
kubeadm certs check-expiration
openssl x509 -in <cert> -noout -dates

# 証明書更新
kubeadm certs renew all

# kubeconfig操作
kubectl config view
kubectl config current-context
kubectl config get-contexts
kubectl config use-context <name>

# CSR操作
kubectl get csr
kubectl certificate approve <name>
kubectl certificate deny <name>
```

---

## ミニ演習（kind対応）

### 演習1: kubeconfig操作

```bash
# 現在のコンテキスト確認
kubectl config current-context

# 全コンテキスト一覧
kubectl config get-contexts

# kubeconfig内容確認
kubectl config view

# 特定の情報抽出
kubectl config view -o jsonpath='{.clusters[*].name}'
kubectl config view -o jsonpath='{.users[*].name}'
```

### 演習2: 新しいコンテキスト作成

```bash
# 新しいNamespace用のコンテキストを追加
kubectl config set-context dev-context \
  --cluster=kind-cka \
  --user=kind-cka \
  --namespace=default

# 確認
kubectl config get-contexts

# コンテキスト切り替え
kubectl config use-context dev-context

# 元に戻す
kubectl config use-context kind-cka

# クリーンアップ
kubectl config delete-context dev-context
```

### 演習3: 証明書情報の確認（読み取りのみ）

kindでは証明書ファイルに直接アクセスできませんが、kubeconfig内の情報は確認できます:

```bash
# kubeconfigの証明書データを確認
kubectl config view --raw -o jsonpath='{.users[0].user.client-certificate-data}' | base64 -d | openssl x509 -noout -subject -dates

# クラスタのCA確認
kubectl config view --raw -o jsonpath='{.clusters[0].cluster.certificate-authority-data}' | base64 -d | openssl x509 -noout -subject
```

> **注意**: 本番CKA試験では `/etc/kubernetes/pki/` 配下の証明書を直接操作します。
> コマンド構文を覚えておくことが重要です。
