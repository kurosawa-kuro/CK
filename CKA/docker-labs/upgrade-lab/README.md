# Kubernetes クラスタアップグレード演習

CKA試験で必出の kubeadm クラスタアップグレードを学習するための資料です。

> **注意**: kindクラスタではkubeadm upgradeを実行できないため、
> このドキュメントは手順の学習とコマンド暗記用です。
> 実際の試験では、提供されたクラスタで実行します。

---

## アップグレードの全体フロー

```
1. control-plane ノードのアップグレード
   └── kubeadm upgrade
   └── kubelet/kubectl upgrade

2. worker ノードのアップグレード（各ノードで繰り返し）
   └── drain
   └── kubeadm upgrade
   └── kubelet upgrade
   └── uncordon
```

---

## 演習1: アップグレード計画の確認

### CKA試験での典型的な問題

> クラスタを v1.29.0 から v1.30.0 にアップグレードしてください。
> まずcontrol-planeノードをアップグレードし、その後workerノードをアップグレードしてください。

### Step 1: 現在のバージョン確認

```bash
# クラスタバージョン確認
kubectl version

# ノードのバージョン確認
kubectl get nodes

# kubeadmバージョン確認
kubeadm version
```

### Step 2: 利用可能なバージョン確認

```bash
# Ubuntuの場合
apt update
apt-cache madison kubeadm | head -10
```

---

## 演習2: Control Plane アップグレード

### Step 1: kubeadm アップグレード

```bash
# パッケージホールド解除
apt-mark unhold kubeadm

# kubeadm インストール
apt-get update
apt-get install -y kubeadm=1.30.0-1.1

# パッケージホールド
apt-mark hold kubeadm

# バージョン確認
kubeadm version
```

### Step 2: アップグレード計画確認

```bash
kubeadm upgrade plan
```

**出力例:**
```
Components that must be upgraded manually after you have upgraded the control plane with 'kubeadm upgrade apply':
COMPONENT   CURRENT       TARGET
kubelet     v1.29.0       v1.30.0

Upgrade to the latest stable version:

COMPONENT                 CURRENT   TARGET
kube-apiserver            v1.29.0   v1.30.0
kube-controller-manager   v1.29.0   v1.30.0
kube-scheduler            v1.29.0   v1.30.0
kube-proxy                v1.29.0   v1.30.0
CoreDNS                   v1.11.1   v1.11.1
etcd                      3.5.10    3.5.12

You can now apply the upgrade by executing the following command:

        kubeadm upgrade apply v1.30.0
```

### Step 3: アップグレード実行

```bash
kubeadm upgrade apply v1.30.0
```

**確認プロンプト:**
```
[upgrade/confirm] Are you sure you want to proceed with the upgrade? [y/N]: y
```

### Step 4: kubelet/kubectl アップグレード

```bash
# ノードをdrain（control-planeの場合は自分自身）
kubectl drain <control-plane-node> --ignore-daemonsets

# パッケージアップグレード
apt-mark unhold kubelet kubectl
apt-get update
apt-get install -y kubelet=1.30.0-1.1 kubectl=1.30.0-1.1
apt-mark hold kubelet kubectl

# kubelet再起動
systemctl daemon-reload
systemctl restart kubelet

# uncordon
kubectl uncordon <control-plane-node>
```

### Step 5: 確認

```bash
kubectl get nodes
```

**期待する出力:**
```
NAME                 STATUS   ROLES           AGE   VERSION
control-plane        Ready    control-plane   10d   v1.30.0
worker-1             Ready    <none>          10d   v1.29.0
worker-2             Ready    <none>          10d   v1.29.0
```

---

## 演習3: Worker ノードアップグレード

### 各workerノードで以下を実行

#### Step 1: ノードをdrain（control-planeから実行）

```bash
kubectl drain <worker-node> --ignore-daemonsets --delete-emptydir-data
```

#### Step 2: kubeadm アップグレード（workerノードで実行）

```bash
# SSHでworkerノードに接続
ssh <worker-node>

# kubeadm アップグレード
apt-mark unhold kubeadm
apt-get update
apt-get install -y kubeadm=1.30.0-1.1
apt-mark hold kubeadm

# ノード設定アップグレード
kubeadm upgrade node
```

#### Step 3: kubelet アップグレード（workerノードで実行）

```bash
apt-mark unhold kubelet kubectl
apt-get update
apt-get install -y kubelet=1.30.0-1.1 kubectl=1.30.0-1.1
apt-mark hold kubelet kubectl

systemctl daemon-reload
systemctl restart kubelet
```

#### Step 4: uncordon（control-planeから実行）

```bash
kubectl uncordon <worker-node>
```

#### Step 5: 次のworkerノードへ

上記 Step 1-4 を各workerノードで繰り返す。

---

## アップグレードコマンド一覧（暗記用）

### Control Plane

```bash
# 1. kubeadm アップグレード
apt-mark unhold kubeadm
apt-get update && apt-get install -y kubeadm=1.30.0-1.1
apt-mark hold kubeadm

# 2. アップグレード計画確認
kubeadm upgrade plan

# 3. アップグレード実行
kubeadm upgrade apply v1.30.0

# 4. drain
kubectl drain <node> --ignore-daemonsets

# 5. kubelet/kubectl アップグレード
apt-mark unhold kubelet kubectl
apt-get install -y kubelet=1.30.0-1.1 kubectl=1.30.0-1.1
apt-mark hold kubelet kubectl

# 6. kubelet再起動
systemctl daemon-reload
systemctl restart kubelet

# 7. uncordon
kubectl uncordon <node>
```

### Worker Node

```bash
# 1. drain（control-planeから）
kubectl drain <worker> --ignore-daemonsets --delete-emptydir-data

# 2. kubeadm（workerで）
apt-mark unhold kubeadm
apt-get install -y kubeadm=1.30.0-1.1
apt-mark hold kubeadm
kubeadm upgrade node

# 3. kubelet（workerで）
apt-mark unhold kubelet kubectl
apt-get install -y kubelet=1.30.0-1.1 kubectl=1.30.0-1.1
apt-mark hold kubelet kubectl
systemctl daemon-reload
systemctl restart kubelet

# 4. uncordon（control-planeから）
kubectl uncordon <worker>
```

---

## よくあるミス

| ミス | 症状 | 対処法 |
|-----|-----|-------|
| kubeadm upgrade前にkubeletアップグレード | 互換性エラー | 順序を守る: kubeadm → kubelet |
| apt-mark hold忘れ | 自動更新で壊れる | 必ずholdする |
| systemctl restart忘れ | 古いバージョンのまま | daemon-reload + restart |
| drain忘れ | ワークロード中断 | 必ずdrain → upgrade → uncordon |
| Control Plane前にWorkerアップグレード | API互換性問題 | Control Plane → Worker の順序 |

---

## バージョン番号の書き方

### apt パッケージ形式
```
kubeadm=1.30.0-1.1
kubelet=1.30.0-1.1
kubectl=1.30.0-1.1
```

### kubeadm upgrade apply 形式
```
kubeadm upgrade apply v1.30.0
```

> **注意**: aptは `=1.30.0-1.1`、kubeadmは `v1.30.0` と書き方が異なる

---

## CKA試験でのポイント

1. **時間配分**: アップグレード問題は時間がかかる（15-20分）
2. **順序**: Control Plane → Worker の順序を絶対に守る
3. **ノード名**: 問題文のノード名を正確に使う
4. **バージョン**: 問題文のバージョンを正確に使う（v1.30.0 vs 1.30.0-1.1）

---

## 関連ドキュメント

- [03_クラスタアップグレード.md](../../test/CKA特化知識/03_クラスタアップグレード.md)
