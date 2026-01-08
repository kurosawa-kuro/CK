# CKA特化: RBAC (Role-Based Access Control)

## 概要

RBACは「誰が」「何に対して」「何ができるか」を制御する仕組み。
CKA試験では**作成・修正・トラブルシューティング**が頻出。

### 実技問題との対応

| 実技問題 | 使用する知識 |
|---------|------------|
| 問題2: ClusterRole/ClusterRoleBinding | ClusterRole作成、ClusterRoleBinding作成、ServiceAccountとの紐付け |

---

## RBACの4つのリソース

```
┌─────────────────────────────────────────────────────────────┐
│                    Namespace スコープ                        │
│  ┌──────────────┐          ┌──────────────────┐           │
│  │    Role      │◀────────▶│  RoleBinding     │           │
│  │  (権限定義)   │          │  (紐付け)        │           │
│  └──────────────┘          └──────────────────┘           │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                    Cluster スコープ                          │
│  ┌──────────────┐          ┌──────────────────┐           │
│  │ ClusterRole  │◀────────▶│ClusterRoleBinding│           │
│  │  (権限定義)   │          │  (紐付け)        │           │
│  └──────────────┘          └──────────────────┘           │
└─────────────────────────────────────────────────────────────┘
```

| リソース | スコープ | 用途 |
|---------|---------|------|
| Role | Namespace | 名前空間内のリソースへの権限 |
| ClusterRole | Cluster | クラスタ全体/非Namespace リソース |
| RoleBinding | Namespace | Role/ClusterRole を User/SA に紐付け |
| ClusterRoleBinding | Cluster | ClusterRole を全体に紐付け |

---

## 1. Role（名前空間スコープ）

### YAMLで作成

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: pod-reader
  namespace: default
rules:
- apiGroups: [""]          # "" = core API group
  resources: ["pods"]
  verbs: ["get", "watch", "list"]
```

### コマンドで作成

```bash
# Roleを作成
kubectl create role pod-reader \
  --verb=get,list,watch \
  --resource=pods \
  -n default

# 確認
kubectl get role -n default
kubectl describe role pod-reader -n default
```

---

## 2. ClusterRole（クラスタスコープ）

### YAMLで作成

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: node-reader
rules:
- apiGroups: [""]
  resources: ["nodes"]
  verbs: ["get", "watch", "list"]
```

### コマンドで作成

```bash
# ClusterRoleを作成
kubectl create clusterrole node-reader \
  --verb=get,list,watch \
  --resource=nodes

# PersistentVolume用
kubectl create clusterrole pv-reader \
  --verb=get,list \
  --resource=persistentvolumes
```

---

## 3. RoleBinding（名前空間スコープ）

### YAMLで作成

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: read-pods
  namespace: default
subjects:
- kind: User
  name: jane
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io
```

### コマンドで作成

```bash
# User に Role を紐付け
kubectl create rolebinding read-pods \
  --role=pod-reader \
  --user=jane \
  -n default

# ServiceAccount に Role を紐付け
kubectl create rolebinding read-pods-sa \
  --role=pod-reader \
  --serviceaccount=default:my-sa \
  -n default

# ClusterRole を Namespace 内で紐付け（よくある）
kubectl create rolebinding read-pods-cr \
  --clusterrole=view \
  --user=jane \
  -n default
```

---

## 4. ClusterRoleBinding（クラスタスコープ）

### YAMLで作成

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: read-nodes-global
subjects:
- kind: User
  name: jane
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: node-reader
  apiGroup: rbac.authorization.k8s.io
```

### コマンドで作成

```bash
# User に ClusterRole を紐付け（全Namespace）
kubectl create clusterrolebinding read-nodes-global \
  --clusterrole=node-reader \
  --user=jane

# Group に ClusterRole を紐付け
kubectl create clusterrolebinding admin-group \
  --clusterrole=admin \
  --group=developers
```

---

## Verbs（操作権限）

| Verb | 説明 | kubectl操作 |
|------|------|------------|
| `get` | 単一リソースの取得 | kubectl get pod <name> |
| `list` | リソース一覧の取得 | kubectl get pods |
| `watch` | 変更の監視 | kubectl get pods -w |
| `create` | 作成 | kubectl create |
| `update` | 更新（replace） | kubectl apply |
| `patch` | 部分更新 | kubectl patch |
| `delete` | 削除 | kubectl delete |
| `deletecollection` | 一括削除 | kubectl delete --all |

### よく使う組み合わせ

```yaml
# 読み取り専用
verbs: ["get", "list", "watch"]

# フル権限
verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]

# 全ての操作
verbs: ["*"]
```

---

## API Groups

| リソース | apiGroups |
|---------|-----------|
| pods, services, secrets, configmaps | `""` (core) |
| deployments, replicasets | `apps` |
| jobs, cronjobs | `batch` |
| ingresses | `networking.k8s.io` |
| persistentvolumeclaims | `""` |
| persistentvolumes | `""` |
| nodes | `""` |

### apiGroupsの確認方法

```bash
kubectl api-resources

# 出力例
# NAME          SHORTNAMES   APIVERSION   NAMESPACED   KIND
# pods          po           v1           true         Pod
# deployments   deploy       apps/v1      true         Deployment
```

---

## ServiceAccount

### 作成

```bash
# ServiceAccount作成
kubectl create serviceaccount my-sa -n default

# 確認
kubectl get sa -n default
```

### PodでServiceAccountを使用

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: my-pod
spec:
  serviceAccountName: my-sa  # ここで指定
  containers:
  - name: nginx
    image: nginx
```

### ServiceAccountにRoleを紐付け

```bash
kubectl create rolebinding my-sa-binding \
  --role=pod-reader \
  --serviceaccount=default:my-sa \
  -n default
```

---

## 権限確認（can-i）

### 自分の権限確認

```bash
# 自分がPodを作成できるか
kubectl auth can-i create pods

# 特定の名前空間で
kubectl auth can-i create pods -n kube-system
```

### 他ユーザーの権限確認（管理者用）

```bash
# jane が pods を get できるか
kubectl auth can-i get pods --as jane

# ServiceAccount として
kubectl auth can-i list pods --as system:serviceaccount:default:my-sa

# 特定の名前空間で
kubectl auth can-i delete pods --as jane -n production
```

### 全権限の一覧表示

```bash
# 自分の全権限
kubectl auth can-i --list

# 特定ユーザーの全権限
kubectl auth can-i --list --as jane
```

---

## 試験頻出パターン

### パターン1: ServiceAccountにPod読み取り権限

```bash
# 1. ServiceAccount作成
kubectl create sa pod-reader -n default

# 2. Role作成
kubectl create role pod-reader-role \
  --verb=get,list,watch \
  --resource=pods \
  -n default

# 3. RoleBinding作成
kubectl create rolebinding pod-reader-binding \
  --role=pod-reader-role \
  --serviceaccount=default:pod-reader \
  -n default
```

### パターン2: 全Namespaceでの読み取り権限

```bash
# ClusterRole を使用
kubectl create clusterrole pod-reader \
  --verb=get,list,watch \
  --resource=pods

# ClusterRoleBinding で全体に適用
kubectl create clusterrolebinding pod-reader-global \
  --clusterrole=pod-reader \
  --user=jane
```

### パターン3: 特定リソース名への権限

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: specific-pod-reader
  namespace: default
rules:
- apiGroups: [""]
  resources: ["pods"]
  resourceNames: ["my-pod", "important-pod"]  # 特定のPodのみ
  verbs: ["get", "watch"]
```

---

## デフォルトClusterRole

| ClusterRole | 権限 |
|------------|------|
| `view` | 読み取り専用（Secret以外） |
| `edit` | 作成・更新・削除（RBACを除く） |
| `admin` | Namespace内の全権限（RBACを含む） |
| `cluster-admin` | クラスタ全体の全権限 |

```bash
# デフォルトClusterRoleを使う例
kubectl create rolebinding jane-view \
  --clusterrole=view \
  --user=jane \
  -n default
```

---

## トラブルシューティング

### エラー: User "jane" cannot get pods

```bash
# 1. 現在の権限確認
kubectl auth can-i get pods --as jane -n default

# 2. RoleBindingの確認
kubectl get rolebinding -n default
kubectl describe rolebinding <binding-name> -n default

# 3. Roleの確認
kubectl describe role <role-name> -n default

# 4. 修正（足りない権限を追加）
kubectl edit role <role-name> -n default
```

### よくある間違い

| 間違い | 正しい |
|-------|-------|
| apiGroups を指定忘れ | `apiGroups: [""]` for core |
| RoleBinding の namespace 忘れ | `-n <namespace>` |
| ServiceAccount の形式 | `namespace:name` |
| ClusterRole を RoleBinding で使う時 | roleRef.kind: ClusterRole |

---

## クイックリファレンス

```bash
# Role作成
kubectl create role <name> --verb=get,list --resource=pods -n <ns>

# ClusterRole作成
kubectl create clusterrole <name> --verb=get,list --resource=nodes

# RoleBinding作成（User）
kubectl create rolebinding <name> --role=<role> --user=<user> -n <ns>

# RoleBinding作成（ServiceAccount）
kubectl create rolebinding <name> --role=<role> --serviceaccount=<ns>:<sa> -n <ns>

# ClusterRoleBinding作成
kubectl create clusterrolebinding <name> --clusterrole=<cr> --user=<user>

# 権限確認
kubectl auth can-i <verb> <resource> --as <user> -n <ns>
```

---

## ミニ演習（kind対応）

### 演習1: Role/RoleBinding作成

```bash
# Namespace作成
kubectl create namespace rbac-demo

# Step 1: pod-readerロールを作成
kubectl create role pod-reader \
  --verb=get,list,watch \
  --resource=pods \
  -n rbac-demo

# Step 2: ServiceAccount作成
kubectl create serviceaccount demo-sa -n rbac-demo

# Step 3: RoleBinding作成
kubectl create rolebinding demo-binding \
  --role=pod-reader \
  --serviceaccount=rbac-demo:demo-sa \
  -n rbac-demo

# 確認
kubectl describe role pod-reader -n rbac-demo
kubectl describe rolebinding demo-binding -n rbac-demo
```

### 演習2: 権限テスト

```bash
# 権限確認コマンド
kubectl auth can-i get pods --as system:serviceaccount:rbac-demo:demo-sa -n rbac-demo
# yes

kubectl auth can-i delete pods --as system:serviceaccount:rbac-demo:demo-sa -n rbac-demo
# no

kubectl auth can-i get pods --as system:serviceaccount:rbac-demo:demo-sa -n default
# no（別Namespaceは不可）
```

### 演習3: ClusterRole/ClusterRoleBinding

```bash
# Step 1: ClusterRole作成（ノード読み取り）
kubectl create clusterrole node-viewer \
  --verb=get,list,watch \
  --resource=nodes

# Step 2: ClusterRoleBinding作成
kubectl create clusterrolebinding node-viewer-binding \
  --clusterrole=node-viewer \
  --serviceaccount=rbac-demo:demo-sa

# 権限確認（クラスタ全体）
kubectl auth can-i get nodes --as system:serviceaccount:rbac-demo:demo-sa
# yes
```

### クリーンアップ

```bash
kubectl delete namespace rbac-demo
kubectl delete clusterrole node-viewer
kubectl delete clusterrolebinding node-viewer-binding
```

---

## 段階的ハンズオン（実技問題への橋渡し）

### レベル1: 基礎（各リソースの理解）

#### 演習1-1: Role の作成と確認

```bash
# 準備
kubectl create namespace rbac-basic

# 1. Role作成
kubectl create role pod-reader \
  --verb=get,list,watch \
  --resource=pods \
  -n rbac-basic

# 2. 内容確認
kubectl describe role pod-reader -n rbac-basic

# 出力の読み方:
# Resources: pods（対象リソース）
# Verbs: get, list, watch（許可される操作）

# 3. YAML形式で確認
kubectl get role pod-reader -n rbac-basic -o yaml
```

**理解ポイント:**
- `apiGroups: [""]` は core API（pods, services等）
- verbs は許可する操作の種類

#### 演習1-2: ClusterRole の作成と確認

```bash
# 1. ClusterRole作成（ノード読み取り）
kubectl create clusterrole node-reader \
  --verb=get,list,watch \
  --resource=nodes

# 2. 内容確認
kubectl describe clusterrole node-reader

# 3. ClusterRoleとRoleの違いを確認
kubectl get role -A | head -10
kubectl get clusterrole | head -10

# クリーンアップ
kubectl delete clusterrole node-reader
```

**理解ポイント:**
- ClusterRole は Namespace に属さない
- nodes は Namespace リソースではないので ClusterRole が必要

#### 演習1-3: ServiceAccount の作成

```bash
# 1. ServiceAccount作成
kubectl create serviceaccount test-sa -n rbac-basic

# 2. 確認
kubectl get sa -n rbac-basic

# 3. 詳細確認
kubectl describe sa test-sa -n rbac-basic
```

**理解ポイント:**
- ServiceAccount は Pod に紐付けて使用
- デフォルトで各 Namespace に `default` SA がある

---

### レベル2: 応用（紐付けと権限確認）

#### 演習2-1: RoleBinding の作成と権限確認

```bash
# 1. Role作成（まだなければ）
kubectl create role pod-reader \
  --verb=get,list,watch \
  --resource=pods \
  -n rbac-basic 2>/dev/null || true

# 2. RoleBinding作成（SAにRoleを紐付け）
kubectl create rolebinding test-binding \
  --role=pod-reader \
  --serviceaccount=rbac-basic:test-sa \
  -n rbac-basic

# 3. 権限確認（can-i）
# 権限あり
kubectl auth can-i get pods \
  --as system:serviceaccount:rbac-basic:test-sa \
  -n rbac-basic
# 出力: yes

# 権限なし（deleteは許可していない）
kubectl auth can-i delete pods \
  --as system:serviceaccount:rbac-basic:test-sa \
  -n rbac-basic
# 出力: no

# 権限なし（別Namespaceは不可）
kubectl auth can-i get pods \
  --as system:serviceaccount:rbac-basic:test-sa \
  -n default
# 出力: no
```

**理解ポイント:**
- `--as system:serviceaccount:<namespace>:<sa-name>` で SA として権限確認
- RoleBinding は そのNamespace内のみ有効

#### 演習2-2: ClusterRoleBinding の作成と権限確認

```bash
# 1. ClusterRole作成
kubectl create clusterrole pod-reader-cluster \
  --verb=get,list,watch \
  --resource=pods

# 2. ClusterRoleBinding作成
kubectl create clusterrolebinding test-cluster-binding \
  --clusterrole=pod-reader-cluster \
  --serviceaccount=rbac-basic:test-sa

# 3. 権限確認（全Namespaceで有効）
kubectl auth can-i get pods \
  --as system:serviceaccount:rbac-basic:test-sa \
  -n default
# 出力: yes

kubectl auth can-i get pods \
  --as system:serviceaccount:rbac-basic:test-sa \
  -n kube-system
# 出力: yes

# クリーンアップ
kubectl delete clusterrole pod-reader-cluster
kubectl delete clusterrolebinding test-cluster-binding
```

**理解ポイント:**
- ClusterRoleBinding は 全Namespace で有効
- 同じ ClusterRole を RoleBinding で使うと、そのNamespace内のみ有効になる

#### 演習2-3: 全権限の一覧表示

```bash
# 自分の権限一覧
kubectl auth can-i --list

# 特定SAの権限一覧
kubectl auth can-i --list \
  --as system:serviceaccount:rbac-basic:test-sa \
  -n rbac-basic
```

**理解ポイント:**
- `--list` で許可されている全操作を確認できる
- トラブルシューティング時に便利

---

### レベル3: 実技問題準備

#### 演習3-1: 問題2シミュレーション（ClusterRole + ClusterRoleBinding）

```bash
# 環境準備
kubectl create namespace rbac-test

# ServiceAccount作成
kubectl create serviceaccount cluster-viewer -n rbac-test

# kubectl Podを作成（SA指定）
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: kubectl-pod
  namespace: rbac-test
spec:
  serviceAccountName: cluster-viewer
  containers:
  - name: kubectl
    image: bitnami/kubectl:latest
    command: ["sleep", "infinity"]
EOF

# Pod起動待ち
sleep 10

# === 権限がない状態を確認 ===
kubectl exec -n rbac-test kubectl-pod -- kubectl get pods -A 2>&1 | head -3
# Error from server (Forbidden)...

kubectl exec -n rbac-test kubectl-pod -- kubectl get nodes 2>&1 | head -3
# Error from server (Forbidden)...

# === 問題開始 ===
# タスク1: ClusterRole作成（pods, nodes の get,list,watch）
kubectl create clusterrole pod-node-reader \
  --verb=get,list,watch \
  --resource=pods,nodes

# タスク2: ClusterRoleBinding作成
kubectl create clusterrolebinding cluster-viewer-binding \
  --clusterrole=pod-node-reader \
  --serviceaccount=rbac-test:cluster-viewer

# === 確認 ===
# Pod一覧取得（成功するはず）
kubectl exec -n rbac-test kubectl-pod -- kubectl get pods -A

# Node一覧取得（成功するはず）
kubectl exec -n rbac-test kubectl-pod -- kubectl get nodes

# クリーンアップ
kubectl delete namespace rbac-test
kubectl delete clusterrole pod-node-reader
kubectl delete clusterrolebinding cluster-viewer-binding
```

#### 演習3-2: トラブルシューティング練習

```bash
# 環境準備
kubectl create namespace rbac-debug
kubectl create serviceaccount debug-sa -n rbac-debug

# 意図的に間違ったRoleBindingを作成
kubectl create role secret-reader \
  --verb=get,list \
  --resource=secrets \
  -n rbac-debug

# 間違い: namespace を間違えて指定
kubectl create rolebinding wrong-binding \
  --role=secret-reader \
  --serviceaccount=default:debug-sa \
  -n rbac-debug

# === トラブルシューティング開始 ===

# 1. 権限確認（失敗するはず）
kubectl auth can-i get secrets \
  --as system:serviceaccount:rbac-debug:debug-sa \
  -n rbac-debug
# 出力: no

# 2. RoleBindingの内容確認
kubectl describe rolebinding wrong-binding -n rbac-debug | grep -A 5 Subjects
# Subjects:
#   Kind   Name       Namespace
#   ----   ----       ---------
#   ServiceAccount  debug-sa   default   <-- ここが間違い！

# 3. 修正: RoleBindingを削除して正しく作り直す
kubectl delete rolebinding wrong-binding -n rbac-debug

kubectl create rolebinding correct-binding \
  --role=secret-reader \
  --serviceaccount=rbac-debug:debug-sa \
  -n rbac-debug

# 4. 再確認
kubectl auth can-i get secrets \
  --as system:serviceaccount:rbac-debug:debug-sa \
  -n rbac-debug
# 出力: yes

# クリーンアップ
kubectl delete namespace rbac-debug
```

**よくあるミス:**
- ServiceAccount の namespace 指定ミス（`default:sa` vs `rbac-debug:sa`）
- Role と ClusterRole の混同
- RoleBinding で ClusterRole を使う時の roleRef.kind 指定

#### 演習3-3: 複数リソースへの権限付与

```bash
# 環境準備
kubectl create namespace multi-rbac
kubectl create serviceaccount multi-sa -n multi-rbac

# 複数リソースへの権限を持つClusterRole作成
cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: multi-reader
rules:
- apiGroups: [""]
  resources: ["pods", "services", "configmaps"]
  verbs: ["get", "list", "watch"]
- apiGroups: ["apps"]
  resources: ["deployments", "replicasets"]
  verbs: ["get", "list", "watch"]
EOF

# ClusterRoleBinding作成
kubectl create clusterrolebinding multi-binding \
  --clusterrole=multi-reader \
  --serviceaccount=multi-rbac:multi-sa

# 確認
kubectl auth can-i get pods \
  --as system:serviceaccount:multi-rbac:multi-sa
kubectl auth can-i get deployments \
  --as system:serviceaccount:multi-rbac:multi-sa
kubectl auth can-i get nodes \
  --as system:serviceaccount:multi-rbac:multi-sa
# pods, deployments は yes、nodes は no

# クリーンアップ
kubectl delete namespace multi-rbac
kubectl delete clusterrole multi-reader
kubectl delete clusterrolebinding multi-binding
```

---

## チートシート

### Role/ClusterRole 作成

```bash
# Role（Namespace内）
kubectl create role <name> --verb=get,list,watch --resource=pods -n <ns>

# ClusterRole（クラスタ全体）
kubectl create clusterrole <name> --verb=get,list,watch --resource=pods,nodes
```

### RoleBinding/ClusterRoleBinding 作成

```bash
# RoleBinding（SAに紐付け）
kubectl create rolebinding <name> \
  --role=<role-name> \
  --serviceaccount=<namespace>:<sa-name> \
  -n <namespace>

# ClusterRoleBinding（SAに紐付け）
kubectl create clusterrolebinding <name> \
  --clusterrole=<clusterrole-name> \
  --serviceaccount=<namespace>:<sa-name>

# RoleBindingでClusterRoleを使う（そのNS内のみ有効）
kubectl create rolebinding <name> \
  --clusterrole=<clusterrole-name> \
  --serviceaccount=<namespace>:<sa-name> \
  -n <namespace>
```

### 権限確認（can-i）

```bash
# 自分の権限
kubectl auth can-i <verb> <resource> -n <ns>

# 他ユーザー/SAの権限
kubectl auth can-i <verb> <resource> \
  --as system:serviceaccount:<namespace>:<sa-name> \
  -n <namespace>

# 全権限一覧
kubectl auth can-i --list \
  --as system:serviceaccount:<namespace>:<sa-name>
```

### よく使うapiGroups

| apiGroups | リソース |
|-----------|---------|
| `""` (core) | pods, services, secrets, configmaps, persistentvolumeclaims, nodes |
| `apps` | deployments, replicasets, statefulsets, daemonsets |
| `batch` | jobs, cronjobs |
| `networking.k8s.io` | ingresses, networkpolicies |

### ServiceAccount 指定形式

```bash
# コマンドでの指定
--serviceaccount=<namespace>:<sa-name>

# YAMLでの指定
subjects:
- kind: ServiceAccount
  name: <sa-name>
  namespace: <namespace>

# can-i での指定
--as system:serviceaccount:<namespace>:<sa-name>
```

### Role vs ClusterRole 選択フロー

```
対象リソースは Namespaced?
├── Yes（pods, services, secrets等）
│   └── 全Namespaceで必要？
│       ├── Yes → ClusterRole + ClusterRoleBinding
│       └── No  → Role + RoleBinding
└── No（nodes, persistentvolumes等）
    └── ClusterRole + ClusterRoleBinding
```
