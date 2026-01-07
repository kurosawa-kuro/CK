# CKA特化 実技問題集

CKA特化知識ドキュメントに対応した実技問題。
各問題の後に解答例を記載。

---

## 目次

1. [クラスタアーキテクチャ](#1-クラスタアーキテクチャ)
2. [etcdバックアップ・リストア](#2-etcdバックアップリストア)
3. [クラスタアップグレード](#3-クラスタアップグレード)
4. [ノード管理](#4-ノード管理)
5. [RBAC](#5-rbac)
6. [トラブルシューティング](#6-トラブルシューティング)
7. [証明書・kubeconfig](#7-証明書kubeconfig)
8. [JSONPath・カスタム出力](#8-jsonpathカスタム出力)

---

# 1. クラスタアーキテクチャ

## 問題 1-1: コンポーネント情報の取得

コントロールプレーンで動作している以下のコンポーネントのイメージバージョンを確認し、
`/opt/component-versions.txt` に以下の形式で保存してください。

```
kube-apiserver: <version>
etcd: <version>
```

---------------------------------------------------------

### 解答 1-1

```bash
# kube-apiserver のイメージ確認
kubectl get pod kube-apiserver-cka-control-plane -n kube-system -o jsonpath='{.spec.containers[0].image}'

# etcd のイメージ確認
kubectl get pod etcd-cka-control-plane -n kube-system -o jsonpath='{.spec.containers[0].image}'

# ファイルに保存
echo "kube-apiserver: $(kubectl get pod kube-apiserver-cka-control-plane -n kube-system -o jsonpath='{.spec.containers[0].image}')" > /opt/component-versions.txt
echo "etcd: $(kubectl get pod etcd-cka-control-plane -n kube-system -o jsonpath='{.spec.containers[0].image}')" >> /opt/component-versions.txt
```

---------------------------------------------------------

## 問題 1-2: 静的Podの作成

cka-control-plane ノードに `static-web` という名前の静的Podを作成してください。

- イメージ: `nginx:alpine`
- ポート: 80

---------------------------------------------------------

### 解答 1-2

```bash
# 静的Podのマニフェスト作成
cat <<EOF > /etc/kubernetes/manifests/static-web.yaml
apiVersion: v1
kind: Pod
metadata:
  name: static-web
spec:
  containers:
  - name: nginx
    image: nginx:alpine
    ports:
    - containerPort: 80
EOF

# 確認（ノード名が付与される）
kubectl get pods | grep static-web
```

---------------------------------------------------------

## 問題 1-3: コンポーネント障害の影響調査

kube-scheduler が停止した場合、以下のどの操作が影響を受けるか調査し、
`/opt/scheduler-impact.txt` に記載してください。

A. 既存Podの動作
B. 新規Podの作成（スケジューリング）
C. kubectl get pods コマンド
D. Serviceの通信

---------------------------------------------------------

### 解答 1-3

```bash
# 正解: B のみ

cat <<EOF > /opt/scheduler-impact.txt
影響を受ける操作: B. 新規Podの作成（スケジューリング）

理由:
- A. 既存Podの動作: 影響なし（kubeletが管理継続）
- B. 新規Podの作成: 影響あり（スケジューラがノード割り当てできない）
- C. kubectl get pods: 影響なし（API Serverが応答）
- D. Serviceの通信: 影響なし（kube-proxyが管理継続）
EOF
```

---------------------------------------------------------

# 2. etcdバックアップ・リストア

## 問題 2-1: etcdスナップショットの作成

etcdのスナップショットを `/opt/etcd-backup.db` に保存してください。

必要な証明書は以下の場所にあります:
- CA証明書: `/etc/kubernetes/pki/etcd/ca.crt`
- サーバー証明書: `/etc/kubernetes/pki/etcd/server.crt`
- サーバー秘密鍵: `/etc/kubernetes/pki/etcd/server.key`

---------------------------------------------------------

### 解答 2-1

```bash
ETCDCTL_API=3 etcdctl snapshot save /opt/etcd-backup.db \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key

# 確認
ETCDCTL_API=3 etcdctl snapshot status /opt/etcd-backup.db --write-out=table
```

---------------------------------------------------------

## 問題 2-2: etcdスナップショットのリストア

`/opt/etcd-backup.db` からetcdをリストアしてください。
リストア先のデータディレクトリは `/var/lib/etcd-restored` とします。

---------------------------------------------------------

### 解答 2-2

```bash
# 1. リストア実行
ETCDCTL_API=3 etcdctl snapshot restore /opt/etcd-backup.db \
  --data-dir=/var/lib/etcd-restored

# 2. etcdマニフェストを編集
vi /etc/kubernetes/manifests/etcd.yaml

# 変更箇所:
# - --data-dir=/var/lib/etcd-restored
# - volumes.hostPath.path=/var/lib/etcd-restored

# 3. 確認（etcdが再起動するまで待つ）
kubectl get pods -n kube-system | grep etcd
```

---------------------------------------------------------

## 問題 2-3: etcd証明書パスの特定

現在のクラスタで使用されているetcdの証明書パスを確認し、
`/opt/etcd-certs.txt` に以下の形式で保存してください。

```
cacert: <path>
cert: <path>
key: <path>
```

---------------------------------------------------------

### 解答 2-3

```bash
# etcd Podの設定から確認
kubectl describe pod etcd-cka-control-plane -n kube-system | grep -E "(cert|key|ca)" | head -5

# または直接マニフェストから
cat /etc/kubernetes/manifests/etcd.yaml | grep -E "(cert-file|key-file|trusted-ca-file)"

# ファイルに保存
cat <<EOF > /opt/etcd-certs.txt
cacert: /etc/kubernetes/pki/etcd/ca.crt
cert: /etc/kubernetes/pki/etcd/server.crt
key: /etc/kubernetes/pki/etcd/server.key
EOF
```

---------------------------------------------------------

# 3. クラスタアップグレード

## 問題 3-1: アップグレード可能なバージョン確認

現在のクラスタバージョンと、アップグレード可能なバージョンを確認し、
`/opt/upgrade-info.txt` に記載してください。

---------------------------------------------------------

### 解答 3-1

```bash
# 現在のバージョン
kubectl version --short

# kubeadm upgrade plan
kubeadm upgrade plan

# 利用可能なkubeadmバージョン
apt-cache madison kubeadm | head -5

# 結果をファイルに保存
cat <<EOF > /opt/upgrade-info.txt
現在のバージョン: $(kubectl version --short | grep Server)
アップグレード可能: $(kubeadm upgrade plan 2>/dev/null | grep "You can now apply" | head -1)
EOF
```

---------------------------------------------------------

## 問題 3-2: コントロールプレーンのアップグレード（シミュレーション）

コントロールプレーンノードを v1.30.0 にアップグレードする手順を
`/opt/upgrade-steps.txt` に記載してください。

※実際のアップグレードは行わなくてOK

---------------------------------------------------------

### 解答 3-2

```bash
cat <<'EOF' > /opt/upgrade-steps.txt
# コントロールプレーンアップグレード手順

# 1. kubeadmのアップグレード
apt-mark unhold kubeadm
apt-get update && apt-get install -y kubeadm=1.30.0-00
apt-mark hold kubeadm

# 2. アップグレードプラン確認
kubeadm upgrade plan

# 3. アップグレード実行
kubeadm upgrade apply v1.30.0

# 4. ノードをdrain
kubectl drain cka-control-plane --ignore-daemonsets

# 5. kubelet/kubectlアップグレード
apt-mark unhold kubelet kubectl
apt-get update && apt-get install -y kubelet=1.30.0-00 kubectl=1.30.0-00
apt-mark hold kubelet kubectl

# 6. kubelet再起動
systemctl daemon-reload
systemctl restart kubelet

# 7. ノードをuncordon
kubectl uncordon cka-control-plane
EOF
```

---------------------------------------------------------

## 問題 3-3: ワーカーノードのアップグレード（シミュレーション）

ワーカーノード `cka-worker` を v1.30.0 にアップグレードする手順を
`/opt/worker-upgrade-steps.txt` に記載してください。

---------------------------------------------------------

### 解答 3-3

```bash
cat <<'EOF' > /opt/worker-upgrade-steps.txt
# ワーカーノード(cka-worker)アップグレード手順

# コントロールプレーンから実行:
kubectl drain cka-worker --ignore-daemonsets

# cka-worker上で実行:
apt-mark unhold kubeadm
apt-get update && apt-get install -y kubeadm=1.30.0-00
apt-mark hold kubeadm

kubeadm upgrade node

apt-mark unhold kubelet kubectl
apt-get update && apt-get install -y kubelet=1.30.0-00 kubectl=1.30.0-00
apt-mark hold kubelet kubectl

systemctl daemon-reload
systemctl restart kubelet

# コントロールプレーンから実行:
kubectl uncordon cka-worker
EOF
```

---------------------------------------------------------

# 4. ノード管理

## 問題 4-1: ノードのメンテナンス

`cka-worker` ノードをメンテナンスモードにしてください。
- 新しいPodがスケジュールされないようにする
- 既存のPodを安全に退避させる（DaemonSetは無視）

メンテナンス完了後、ノードを通常状態に戻してください。

---------------------------------------------------------

### 解答 4-1

```bash
# 1. ノードをdrain（cordon + Pod退避）
kubectl drain cka-worker --ignore-daemonsets

# 確認
kubectl get nodes
# cka-worker は SchedulingDisabled になっている

# 2. メンテナンス作業を実施...

# 3. ノードを通常状態に戻す
kubectl uncordon cka-worker

# 確認
kubectl get nodes
```

---------------------------------------------------------

## 問題 4-2: Taintの設定

`cka-worker` に以下のTaintを追加してください:
- key: `maintenance`
- value: `true`
- effect: `NoSchedule`

その後、このTaintを許容するPod `tolerant-pod` を作成してください。
- イメージ: `nginx`
- Namespace: `default`

---------------------------------------------------------

### 解答 4-2

```bash
# 1. Taintを追加
kubectl taint nodes cka-worker maintenance=true:NoSchedule

# 確認
kubectl describe node cka-worker | grep Taint

# 2. Tolerationを持つPodを作成
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: tolerant-pod
  namespace: default
spec:
  containers:
  - name: nginx
    image: nginx
  tolerations:
  - key: "maintenance"
    operator: "Equal"
    value: "true"
    effect: "NoSchedule"
  nodeSelector:
    kubernetes.io/hostname: cka-worker
EOF

# 確認
kubectl get pod tolerant-pod -o wide

# クリーンアップ（Taint削除）
kubectl taint nodes cka-worker maintenance=true:NoSchedule-
```

---------------------------------------------------------

## 問題 4-3: NodeAffinityの設定

以下の条件でPodを作成してください:
- Pod名: `gpu-pod`
- イメージ: `nginx`
- 条件: `disktype=ssd` のラベルを持つノードに**必ず**スケジュールされる

まず `cka-worker` に `disktype=ssd` ラベルを追加してから、Podを作成してください。

---------------------------------------------------------

### 解答 4-3

```bash
# 1. ノードにラベルを追加
kubectl label nodes cka-worker disktype=ssd

# 確認
kubectl get nodes --show-labels | grep disktype

# 2. NodeAffinityを持つPodを作成
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: gpu-pod
spec:
  containers:
  - name: nginx
    image: nginx
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
        - matchExpressions:
          - key: disktype
            operator: In
            values:
            - ssd
EOF

# 確認
kubectl get pod gpu-pod -o wide

# クリーンアップ
kubectl label nodes cka-worker disktype-
```

---------------------------------------------------------

# 5. RBAC

## 問題 5-1: Role と RoleBinding の作成

`dev` 名前空間で以下の設定を行ってください:

1. ServiceAccount `app-sa` を作成
2. Role `pod-reader` を作成（pods に対する get, list, watch 権限）
3. RoleBinding `app-sa-binding` で ServiceAccount と Role を紐付け

---------------------------------------------------------

### 解答 5-1

```bash
# 1. Namespace作成（なければ）
kubectl create namespace dev

# 2. ServiceAccount作成
kubectl create serviceaccount app-sa -n dev

# 3. Role作成
kubectl create role pod-reader \
  --verb=get,list,watch \
  --resource=pods \
  -n dev

# 4. RoleBinding作成
kubectl create rolebinding app-sa-binding \
  --role=pod-reader \
  --serviceaccount=dev:app-sa \
  -n dev

# 確認
kubectl auth can-i get pods --as=system:serviceaccount:dev:app-sa -n dev
# yes
```

---------------------------------------------------------

## 問題 5-2: ClusterRole と ClusterRoleBinding

ユーザー `jane` に対して、クラスタ全体のノード情報を読み取る権限を付与してください。

1. ClusterRole `node-reader` を作成（nodes に対する get, list, watch 権限）
2. ClusterRoleBinding `jane-node-reader` で紐付け

権限が正しく付与されたことを確認してください。

---------------------------------------------------------

### 解答 5-2

```bash
# 1. ClusterRole作成
kubectl create clusterrole node-reader \
  --verb=get,list,watch \
  --resource=nodes

# 2. ClusterRoleBinding作成
kubectl create clusterrolebinding jane-node-reader \
  --clusterrole=node-reader \
  --user=jane

# 確認
kubectl auth can-i get nodes --as jane
# yes

kubectl auth can-i delete nodes --as jane
# no
```

---------------------------------------------------------

## 問題 5-3: 既存RBACの権限調査

ServiceAccount `dashboard-sa`（namespace: `kubernetes-dashboard`）が
持っている権限を調査し、`/opt/sa-permissions.txt` に保存してください。

---------------------------------------------------------

### 解答 5-3

```bash
# ServiceAccountの権限を確認
kubectl auth can-i --list --as=system:serviceaccount:kubernetes-dashboard:dashboard-sa

# ファイルに保存
kubectl auth can-i --list --as=system:serviceaccount:kubernetes-dashboard:dashboard-sa > /opt/sa-permissions.txt

# または RoleBinding/ClusterRoleBinding を確認
kubectl get rolebindings,clusterrolebindings -A -o wide | grep dashboard-sa
```

---------------------------------------------------------

# 6. トラブルシューティング

## 問題 6-1: Pod起動失敗の調査と修正

`debug` 名前空間に `broken-pod` というPodがありますが、起動に失敗しています。
原因を調査し、修正してください。

### 環境準備
```bash
kubectl create namespace debug
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: broken-pod
  namespace: debug
spec:
  containers:
  - name: nginx
    image: nginx:invalid-tag-12345
EOF
```

---------------------------------------------------------

### 解答 6-1

```bash
# 1. 状態確認
kubectl get pod broken-pod -n debug
# ImagePullBackOff または ErrImagePull

# 2. 詳細確認
kubectl describe pod broken-pod -n debug | tail -20
# Events に "Failed to pull image" が表示される

# 3. 原因: イメージタグが存在しない

# 4. 修正
kubectl set image pod/broken-pod nginx=nginx:latest -n debug

# または edit
kubectl edit pod broken-pod -n debug
# image: nginx:latest に変更

# 5. 確認
kubectl get pod broken-pod -n debug
# Running になる
```

---------------------------------------------------------

## 問題 6-2: Node NotReady の調査

`cka-worker` が `NotReady` 状態になっています。原因を調査し、修正してください。

### 環境準備（cka-worker上で実行）
```bash
# kubeletを停止してNotReady状態を作る
sudo systemctl stop kubelet
```

---------------------------------------------------------

### 解答 6-2

```bash
# 1. ノード状態確認
kubectl get nodes
# cka-worker が NotReady

# 2. ノード詳細確認
kubectl describe node cka-worker | grep -A5 Conditions

# 3. cka-worker にアクセス（kindの場合はdocker exec）
docker exec -it cka-worker /bin/bash

# 4. kubelet状態確認
systemctl status kubelet
# inactive (dead)

# 5. kubeletログ確認
journalctl -u kubelet | tail -50

# 6. kubelet起動
systemctl start kubelet

# 7. 確認
systemctl status kubelet
# active (running)

# 8. コントロールプレーンで確認
exit
kubectl get nodes
# cka-worker が Ready になる
```

---------------------------------------------------------

## 問題 6-3: Service接続問題の調査

`web-app` Podが `web-service` 経由でアクセスできません。
原因を調査し、修正してください。

### 環境準備
```bash
kubectl create namespace web
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: web-app
  namespace: web
  labels:
    app: web
spec:
  containers:
  - name: nginx
    image: nginx
    ports:
    - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: web-service
  namespace: web
spec:
  selector:
    app: web-wrong  # 意図的に間違い
  ports:
  - port: 80
    targetPort: 80
EOF
```

---------------------------------------------------------

### 解答 6-3

```bash
# 1. Service確認
kubectl get svc web-service -n web

# 2. Endpoints確認（重要！）
kubectl get endpoints web-service -n web
# <none> - Endpointsが空

# 3. Serviceのselector確認
kubectl describe svc web-service -n web | grep Selector
# Selector: app=web-wrong

# 4. Podのlabel確認
kubectl get pod web-app -n web --show-labels
# Labels: app=web

# 5. 原因: selectorが不一致

# 6. 修正
kubectl patch svc web-service -n web -p '{"spec":{"selector":{"app":"web"}}}'

# または
kubectl edit svc web-service -n web
# selector.app を web に変更

# 7. 確認
kubectl get endpoints web-service -n web
# PodのIPが表示される
```

---------------------------------------------------------

# 7. 証明書・kubeconfig

## 問題 7-1: 証明書有効期限の確認

クラスタの証明書有効期限を確認し、最も早く期限が切れる証明書の名前と
有効期限を `/opt/cert-expiry.txt` に保存してください。

---------------------------------------------------------

### 解答 7-1

```bash
# kubeadm で確認
kubeadm certs check-expiration

# 結果をファイルに保存
kubeadm certs check-expiration | head -10 > /opt/cert-expiry.txt

# または openssl で個別確認
openssl x509 -in /etc/kubernetes/pki/apiserver.crt -noout -dates
```

---------------------------------------------------------

## 問題 7-2: kubeconfigコンテキストの操作

以下の操作を行ってください:

1. 現在のコンテキストを確認
2. 全てのコンテキストを一覧表示
3. `dev-context` という新しいコンテキストを作成
   - cluster: kubernetes
   - user: kubernetes-admin
   - namespace: dev

---------------------------------------------------------

### 解答 7-2

```bash
# 1. 現在のコンテキスト確認
kubectl config current-context

# 2. 全コンテキスト一覧
kubectl config get-contexts

# 3. 新しいコンテキスト作成
kubectl config set-context dev-context \
  --cluster=kubernetes \
  --user=kubernetes-admin \
  --namespace=dev

# 確認
kubectl config get-contexts

# 切り替え（オプション）
kubectl config use-context dev-context
```

---------------------------------------------------------

## 問題 7-3: CSRの承認

ユーザー `john` のCertificateSigningRequestが保留中です。
CSRを承認し、証明書を `/opt/john.crt` に保存してください。

### 環境準備
```bash
# CSR作成
openssl genrsa -out /tmp/john.key 2048
openssl req -new -key /tmp/john.key -out /tmp/john.csr -subj "/CN=john/O=developers"

cat <<EOF | kubectl apply -f -
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: john
spec:
  request: $(cat /tmp/john.csr | base64 | tr -d '\n')
  signerName: kubernetes.io/kube-apiserver-client
  usages:
  - client auth
EOF
```

---------------------------------------------------------

### 解答 7-3

```bash
# 1. CSR確認
kubectl get csr
# john が Pending

# 2. CSR承認
kubectl certificate approve john

# 3. 確認
kubectl get csr john
# Approved,Issued

# 4. 証明書を取得
kubectl get csr john -o jsonpath='{.status.certificate}' | base64 -d > /opt/john.crt

# 5. 確認
openssl x509 -in /opt/john.crt -noout -subject
```

---------------------------------------------------------

# 8. JSONPath・カスタム出力

## 問題 8-1: Pod情報の抽出

全Namespaceの全Podについて、以下の情報を `/opt/all-pods.txt` に保存してください。
形式: `<namespace>/<pod-name>`（1行に1Pod）

---------------------------------------------------------

### 解答 8-1

```bash
kubectl get pods -A -o jsonpath='{range .items[*]}{.metadata.namespace}{"/"}{.metadata.name}{"\n"}{end}' > /opt/all-pods.txt

# または custom-columns
kubectl get pods -A -o custom-columns=INFO:.metadata.namespace/.metadata.name --no-headers > /opt/all-pods.txt

# 確認
cat /opt/all-pods.txt
```

---------------------------------------------------------

## 問題 8-2: Node Internal IPの抽出

全ノードのInternal IPアドレスを `/opt/node-ips.txt` に保存してください。
（1行に1 IP）

---------------------------------------------------------

### 解答 8-2

```bash
kubectl get nodes -o jsonpath='{range .items[*]}{.status.addresses[?(@.type=="InternalIP")].address}{"\n"}{end}' > /opt/node-ips.txt

# 確認
cat /opt/node-ips.txt
```

---------------------------------------------------------

## 問題 8-3: カスタムカラム出力

以下の形式でPod一覧を表示し、`/opt/pod-info.txt` に保存してください。

```
NAME          NODE          IP
<pod-name>    <node-name>   <pod-ip>
```

---------------------------------------------------------

### 解答 8-3

```bash
kubectl get pods -o custom-columns=NAME:.metadata.name,NODE:.spec.nodeName,IP:.status.podIP > /opt/pod-info.txt

# 確認
cat /opt/pod-info.txt
```

---------------------------------------------------------

## 問題 8-4: 条件付き抽出

`Running` 状態のPodの名前のみを `/opt/running-pods.txt` に保存してください。

---------------------------------------------------------

### 解答 8-4

```bash
# 方法1: JSONPath filter
kubectl get pods -o jsonpath='{range .items[?(@.status.phase=="Running")]}{.metadata.name}{"\n"}{end}' > /opt/running-pods.txt

# 方法2: field-selector
kubectl get pods --field-selector=status.phase=Running -o jsonpath='{.items[*].metadata.name}' | tr ' ' '\n' > /opt/running-pods.txt

# 確認
cat /opt/running-pods.txt
```

---------------------------------------------------------

## 問題 8-5: ソートして出力

Podを作成時刻順（古い順）にソートし、Pod名を `/opt/pods-by-age.txt` に保存してください。

---------------------------------------------------------

### 解答 8-5

```bash
kubectl get pods --sort-by=.metadata.creationTimestamp -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}' > /opt/pods-by-age.txt

# 確認
cat /opt/pods-by-age.txt
```

---------------------------------------------------------

# 総合問題

## 総合問題 1: クラスタ健全性チェック

以下の情報を収集し、`/opt/cluster-health.txt` にレポートとして保存してください。

1. ノード数と状態
2. コントロールプレーンコンポーネントの状態
3. 全NamespaceのPod数
4. NotReady状態のPodがあれば名前を列挙

---------------------------------------------------------

### 解答: 総合問題 1

```bash
cat <<EOF > /opt/cluster-health.txt
=== クラスタ健全性レポート ===
作成日時: $(date)

=== ノード状態 ===
$(kubectl get nodes)

=== コントロールプレーン ===
$(kubectl get pods -n kube-system | grep -E "apiserver|controller|scheduler|etcd")

=== 全Namespace Pod数 ===
$(kubectl get pods -A --no-headers | wc -l) pods

=== NotReady Pod ===
$(kubectl get pods -A | grep -v Running | grep -v Completed | grep -v NAME || echo "なし")
EOF

cat /opt/cluster-health.txt
```

---------------------------------------------------------

## 総合問題 2: 障害復旧シナリオ

以下のシナリオを実行してください:

1. etcdのバックアップを `/backup/etcd-pre-change.db` に作成
2. `critical` 名前空間を作成し、`important-app` Podを作成（nginx）
3. etcdを先ほどのバックアップからリストア
4. `critical` 名前空間とPodが消えていることを確認

---------------------------------------------------------

### 解答: 総合問題 2

```bash
# 1. バックアップ作成
mkdir -p /backup
ETCDCTL_API=3 etcdctl snapshot save /backup/etcd-pre-change.db \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key

# 2. 名前空間とPod作成
kubectl create namespace critical
kubectl run important-app --image=nginx -n critical

# 確認
kubectl get pods -n critical

# 3. リストア
ETCDCTL_API=3 etcdctl snapshot restore /backup/etcd-pre-change.db \
  --data-dir=/var/lib/etcd-restored

# etcdマニフェスト編集
vi /etc/kubernetes/manifests/etcd.yaml
# --data-dir=/var/lib/etcd-restored
# volumes.hostPath.path=/var/lib/etcd-restored

# etcd再起動を待つ
sleep 60

# 4. 確認
kubectl get namespace critical
# Error: namespace "critical" not found
# → リストアにより、バックアップ時点の状態に戻った
```

---------------------------------------------------------

# 解答のポイント

## 試験で差がつくポイント

1. **etcd**: 証明書パスを正確に指定、ETCDCTL_API=3 を忘れない
2. **アップグレード**: バージョン形式（v1.30.0 vs 1.30.0-00）に注意
3. **RBAC**: --serviceaccount の形式は `namespace:name`
4. **JSONPath**: 配列には `[*]` または `[0]` を指定
5. **トラブルシューティング**: describe → logs → systemctl の順で調査
