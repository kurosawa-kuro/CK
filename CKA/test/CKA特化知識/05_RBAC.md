# CKA特化: RBAC (Role-Based Access Control)

## 概要

RBACは「誰が」「何に対して」「何ができるか」を制御する仕組み。
CKA試験では**作成・修正・トラブルシューティング**が頻出。

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
