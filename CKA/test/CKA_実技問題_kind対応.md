# CKA 実技問題（kind実行可能）

## 前提条件

multi-node kind クラスタが必要です：

```bash
# kind-config.yaml
cat <<EOF > kind-config.yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
- role: worker
- role: worker
EOF

kind create cluster --name cka --config kind-config.yaml
```

---

=========================================================
問題1
=========================================================
環境準備

次のコマンドを実行して、問題に必要なリソースを作成して下さい。

```bash
kubectl apply -f test/resources/cka/q1-node-maintenance.yaml
```

問題

maintenance名前空間では、web-app Deployment（3レプリカ）とapi-app Deployment（2レプリカ）が実行されています。

クラスタ内の1つのworkerノードに対してメンテナンスを行う必要があります。以下のタスクを実行して下さい。



1. クラスタ内のworkerノードを1つ選択し、新しいPodがスケジュールされないようにして下さい。



2. 選択したノード上で実行中のPodを安全に退避させて下さい。DaemonSetのPodは無視し、ローカルデータを持つPodは強制的に削除して下さい。



3. メンテナンスが完了したと仮定し、ノードを再びスケジュール可能な状態に戻して下さい。



4. 全てのPodが正常に稼働していることを確認して下さい。

---------------------------------------------------------

### 解答

#### 理解すべきポイント
- **cordon**: ノードへの新規Podスケジュールを禁止（既存Podは影響なし）
- **drain**: ノード上のPodを退避させる（他ノードに再スケジュール）
- **uncordon**: スケジュール禁止を解除
- 関連: [04_ノード管理.md](CKA特化知識/04_ノード管理.md)

#### Step 1: ノードの確認とworkerノード選択

```bash
kubectl get nodes
```

**出力例:**
```
NAME                 STATUS   ROLES           AGE   VERSION
cka-control-plane    Ready    control-plane   10m   v1.30.0
cka-worker           Ready    <none>          10m   v1.30.0
cka-worker2          Ready    <none>          10m   v1.30.0
```

**選択:** `cka-worker` をメンテナンス対象とする

#### Step 2: 現在のPod配置を確認

```bash
kubectl get pods -n maintenance -o wide
```

**出力例:**
```
NAME                       READY   STATUS    RESTARTS   AGE   IP           NODE
web-app-xxxx-xxxxx         1/1     Running   0          1m    10.244.1.2   cka-worker
web-app-xxxx-yyyyy         1/1     Running   0          1m    10.244.2.3   cka-worker2
web-app-xxxx-zzzzz         1/1     Running   0          1m    10.244.1.4   cka-worker
api-app-xxxx-aaaaa         1/1     Running   0          1m    10.244.2.5   cka-worker2
api-app-xxxx-bbbbb         1/1     Running   0          1m    10.244.1.6   cka-worker
```

#### Step 3: ノードをcordon（スケジュール禁止）

```bash
kubectl cordon cka-worker
```

**出力例:**
```
node/cka-worker cordoned
```

**なぜ?**
`cordon`は「立入禁止」の意味。新しいPodがこのノードにスケジュールされなくなる。
既存のPodは影響を受けない（まだ動作中）。

**確認:**
```bash
kubectl get nodes
```

**出力例:**
```
NAME                 STATUS                     ROLES           AGE   VERSION
cka-control-plane    Ready                      control-plane   10m   v1.30.0
cka-worker           Ready,SchedulingDisabled   <none>          10m   v1.30.0
cka-worker2          Ready                      <none>          10m   v1.30.0
```

`SchedulingDisabled` が表示されていることを確認。

#### Step 4: ノードをdrain（Pod退避）

```bash
kubectl drain cka-worker --ignore-daemonsets --delete-emptydir-data
```

**出力例:**
```
node/cka-worker already cordoned
WARNING: ignoring DaemonSet-managed Pods: kube-system/kindnet-xxxxx, kube-system/kube-proxy-xxxxx
evicting pod maintenance/web-app-xxxx-xxxxx
evicting pod maintenance/web-app-xxxx-zzzzz
evicting pod maintenance/api-app-xxxx-bbbbb
pod/web-app-xxxx-xxxxx evicted
pod/web-app-xxxx-zzzzz evicted
pod/api-app-xxxx-bbbbb evicted
node/cka-worker drained
```

**なぜ各オプションが必要?**
- `--ignore-daemonsets`: DaemonSetのPod（kube-proxy等）は各ノードに必須なので無視
- `--delete-emptydir-data`: emptyDirボリュームのデータは削除（ローカルデータ）

#### Step 5: メンテナンス完了後、uncordon

```bash
kubectl uncordon cka-worker
```

**出力例:**
```
node/cka-worker uncordoned
```

#### 確認方法

```bash
# ノードの状態確認
kubectl get nodes

# Pod配置確認（全て他ノードで動作中）
kubectl get pods -n maintenance -o wide
```

**期待する出力:**
```
NAME                 STATUS   ROLES           AGE   VERSION
cka-control-plane    Ready    control-plane   15m   v1.30.0
cka-worker           Ready    <none>          15m   v1.30.0
cka-worker2          Ready    <none>          15m   v1.30.0
```

Podは全てcka-worker2で動作。uncordon後も自動的には戻らない（再スケジュールされない限り）。

#### よくあるミス

| ミス | エラーメッセージ | 対処法 |
|-----|---------------|-------|
| `--ignore-daemonsets`忘れ | `cannot delete DaemonSet-managed Pods` | オプション追加 |
| `--delete-emptydir-data`忘れ | `cannot delete Pods with local storage` | オプション追加 |
| cordonせずにdrain | 問題なし（drainはcordonを含む） | - |

---------------------------------------------------------


=========================================================
問題2
=========================================================
環境準備

次のコマンドを実行して、問題に必要なリソースを作成して下さい。

```bash
kubectl apply -f test/resources/cka/q2-cluster-rbac.yaml
```

問題

rbac-test名前空間には、cluster-viewer ServiceAccountを使用するkubectl-pod Deploymentが作成されています。このPodは現在、クラスタ内のリソースを参照する権限がありません。

以下のタスクを実行し、cluster-viewer ServiceAccountにクラスタ全体のPodとNodeを読み取る権限を付与して下さい。



1. pod-node-readerという名前のClusterRoleを作成して下さい。このClusterRoleには以下の権限を付与して下さい：
   - pods: get, list, watch
   - nodes: get, list, watch



2. cluster-viewer-bindingという名前のClusterRoleBindingを作成し、cluster-viewer ServiceAccountにpod-node-reader ClusterRoleを紐付けて下さい。



3. kubectl-pod内からPodとNodeの一覧が取得できることを確認して下さい。

---------------------------------------------------------

### 解答

#### 理解すべきポイント
- **ClusterRole**: クラスタ全体に対する権限を定義（Roleは特定Namespace内のみ）
- **ClusterRoleBinding**: ClusterRoleをユーザー/グループ/ServiceAccountに紐付け
- **ServiceAccount**: Pod内のプロセスがAPI Serverと通信するためのアイデンティティ
- 関連: [05_RBAC.md](CKA特化知識/05_RBAC.md)

#### Step 1: 現在の権限状態を確認

```bash
# kubectl-podを特定
kubectl get pods -n rbac-test

# Pod内から権限テスト（まだ失敗するはず）
kubectl exec -n rbac-test deploy/kubectl-pod -- kubectl get pods -A
```

**出力例（権限なし）:**
```
Error from server (Forbidden): pods is forbidden: User "system:serviceaccount:rbac-test:cluster-viewer" cannot list resource "pods" in API group "" at the cluster scope
```

**なぜ失敗?**
ServiceAccount `cluster-viewer` にはまだ何の権限も付与されていないため。

#### Step 2: ClusterRoleを作成

```bash
kubectl create clusterrole pod-node-reader \
  --verb=get,list,watch \
  --resource=pods,nodes
```

**出力例:**
```
clusterrole.rbac.authorization.k8s.io/pod-node-reader created
```

**なぜ?**
- `--verb=get,list,watch`: 読み取り系の操作を許可
- `--resource=pods,nodes`: 対象リソースを指定
- ClusterRoleは「どんな権限があるか」の定義（まだ誰にも付与されていない）

**確認:**
```bash
kubectl describe clusterrole pod-node-reader
```

**出力例:**
```
Name:         pod-node-reader
PolicyRule:
  Resources  Non-Resource URLs  Resource Names  Verbs
  ---------  -----------------  --------------  -----
  nodes      []                 []              [get list watch]
  pods       []                 []              [get list watch]
```

#### Step 3: ClusterRoleBindingを作成

```bash
kubectl create clusterrolebinding cluster-viewer-binding \
  --clusterrole=pod-node-reader \
  --serviceaccount=rbac-test:cluster-viewer
```

**出力例:**
```
clusterrolebinding.rbac.authorization.k8s.io/cluster-viewer-binding created
```

**なぜ?**
- `--clusterrole=pod-node-reader`: Step 2で作成したClusterRoleを指定
- `--serviceaccount=rbac-test:cluster-viewer`: `<namespace>:<serviceaccount名>` 形式で指定
- ClusterRoleBindingにより、cluster-viewer SAがpod-node-readerの権限を持つ

#### 確認方法

```bash
# Pod内からPod一覧取得
kubectl exec -n rbac-test deploy/kubectl-pod -- kubectl get pods -A

# Pod内からNode一覧取得
kubectl exec -n rbac-test deploy/kubectl-pod -- kubectl get nodes
```

**期待する出力:**
```
NAMESPACE     NAME                                         READY   STATUS    RESTARTS   AGE
kube-system   coredns-xxxxxxx-xxxxx                        1/1     Running   0          20m
kube-system   coredns-xxxxxxx-yyyyy                        1/1     Running   0          20m
...
rbac-test     kubectl-pod-xxxxxxx-xxxxx                    1/1     Running   0          5m
```

```
NAME                 STATUS   ROLES           AGE   VERSION
cka-control-plane    Ready    control-plane   20m   v1.30.0
cka-worker           Ready    <none>          20m   v1.30.0
cka-worker2          Ready    <none>          20m   v1.30.0
```

#### 別解: YAMLで作成

```yaml
# clusterrole.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: pod-node-reader
rules:
- apiGroups: [""]
  resources: ["pods", "nodes"]
  verbs: ["get", "list", "watch"]
---
# clusterrolebinding.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: cluster-viewer-binding
subjects:
- kind: ServiceAccount
  name: cluster-viewer
  namespace: rbac-test
roleRef:
  kind: ClusterRole
  name: pod-node-reader
  apiGroup: rbac.authorization.k8s.io
```

#### よくあるミス

| ミス | 症状 | 対処法 |
|-----|-----|-------|
| Role/RoleBindingを使用 | 他Namespaceのリソースが見えない | ClusterRole/ClusterRoleBindingを使用 |
| ServiceAccount指定ミス | Binding作成後も権限なし | `<namespace>:<sa名>`形式を確認 |
| verbsに`create`等を追加 | セキュリティリスク | 最小権限の原則（必要な権限のみ） |

---------------------------------------------------------


=========================================================
問題3
=========================================================
環境準備

次のコマンドを実行して、問題に必要なリソースを作成して下さい。

```bash
kubectl apply -f test/resources/cka/q3-taint-toleration.yaml
```

問題

taint-test名前空間にcritical-pod Podが作成されていますが、スケジュールされていない可能性があります。

クラスタ内の特定のworkerノードに対してTaintを設定し、critical-podのみがそのノードで実行できるようにして下さい。



1. 1つのworkerノードを選択し、以下のTaintを設定して下さい：
   - key: dedicated
   - value: critical
   - effect: NoSchedule



2. critical-podを削除し、上記のTaintに対応するTolerationを追加した新しいPodを作成して下さい。Pod名はcritical-podのままとします。



3. critical-podがTaintを設定したノードで実行されていることを確認して下さい。

---------------------------------------------------------

### 解答

#### 理解すべきポイント
- **Taint**: ノードに「汚れ」を付けて、通常のPodを弾く
- **Toleration**: Podに「耐性」を付けて、特定のTaintを許容する
- **Effect**: `NoSchedule`（スケジュール禁止）, `NoExecute`（既存Podも追い出し）, `PreferNoSchedule`（できれば避ける）
- 関連: [04_ノード管理.md](CKA特化知識/04_ノード管理.md)

#### Step 1: 現在の状態確認

```bash
# ノード一覧
kubectl get nodes

# critical-podの状態確認
kubectl get pod -n taint-test critical-pod
```

**出力例:**
```
NAME           READY   STATUS    RESTARTS   AGE
critical-pod   1/1     Running   0          1m
```

（現時点ではTaintがないので普通にスケジュールされている）

#### Step 2: workerノードを選択してTaintを設定

```bash
kubectl taint nodes cka-worker dedicated=critical:NoSchedule
```

**出力例:**
```
node/cka-worker tainted
```

**なぜ?**
- `dedicated=critical`: key=value形式のTaint
- `NoSchedule`: このTaintを許容（tolerate）しないPodはスケジュールされない
- 既存のPodには影響なし（`NoExecute`の場合は追い出される）

**確認:**
```bash
kubectl describe node cka-worker | grep -A 3 Taints
```

**出力例:**
```
Taints:             dedicated=critical:NoSchedule
```

#### Step 3: critical-podを削除

```bash
kubectl delete pod -n taint-test critical-pod
```

**出力例:**
```
pod "critical-pod" deleted
```

#### Step 4: Tolerationを追加した新しいPodを作成

```bash
# 元のPodからYAMLを生成
kubectl run critical-pod -n taint-test --image=nginx:alpine \
  --dry-run=client -o yaml > /tmp/critical-pod.yaml
```

YAMLを編集してTolerationを追加:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: critical-pod
  namespace: taint-test
spec:
  containers:
  - name: nginx
    image: nginx:alpine
    ports:
    - containerPort: 80
  tolerations:
  - key: "dedicated"
    operator: "Equal"
    value: "critical"
    effect: "NoSchedule"
  nodeSelector:
    kubernetes.io/hostname: cka-worker  # 確実にTaintノードに配置
```

```bash
kubectl apply -f /tmp/critical-pod.yaml
```

**出力例:**
```
pod/critical-pod created
```

**なぜ?**
- `tolerations`: このPodは`dedicated=critical:NoSchedule`のTaintを許容する
- `operator: Equal`: key, value, effectが完全一致する必要がある
- `nodeSelector`: Taintを設定したノードに確実に配置（任意だが確実性向上）

#### 確認方法

```bash
kubectl get pod -n taint-test critical-pod -o wide
```

**期待する出力:**
```
NAME           READY   STATUS    RESTARTS   AGE   IP           NODE
critical-pod   1/1     Running   0          30s   10.244.1.5   cka-worker
```

`NODE`列が`cka-worker`（Taintを設定したノード）であることを確認。

#### 別解: nodeSelectorなしでTolerationsのみ

```yaml
tolerations:
- key: "dedicated"
  operator: "Equal"
  value: "critical"
  effect: "NoSchedule"
```

この場合、Taintノードにもスケジュール可能になるが、他のノードにも配置される可能性がある。

#### クリーンアップ（問題後）

```bash
# Taintの削除（末尾に-を付ける）
kubectl taint nodes cka-worker dedicated=critical:NoSchedule-
```

#### よくあるミス

| ミス | 症状 | 対処法 |
|-----|-----|-------|
| Toleration設定ミス（key/value/effect不一致） | PodがPending | Taintの設定と完全一致させる |
| `NoExecute`を使用 | 既存Podが追い出される | 用途に応じてeffectを選択 |
| Toleration削除を忘れて`-`なしで実行 | エラー | `key=value:effect-` の形式で削除 |

---------------------------------------------------------


=========================================================
問題4
=========================================================
環境準備

次のコマンドを実行して、問題に必要なリソースを作成して下さい。

```bash
kubectl apply -f test/resources/cka/q4-daemonset.yaml
```

問題

monitoring名前空間には、node-exporter DaemonSetが作成されています。このDaemonSetは全てのノード（control-planeを含む）で実行される必要がありますが、現在control-planeノードではPodが実行されていません。

以下のタスクを実行して下さい。



1. node-exporter DaemonSetのPodがcontrol-planeノードで実行されていない理由を調査して下さい。



2. DaemonSetを修正し、control-planeノードを含む全てのノードでPodが実行されるようにして下さい。
   ヒント: control-planeノードには通常 `node-role.kubernetes.io/control-plane:NoSchedule` というTaintが設定されています。



3. 全てのノードでnode-exporter Podが実行されていることを確認して下さい。

---------------------------------------------------------

### 解答

#### 理解すべきポイント
- **DaemonSet**: 全ノード（または指定ノード）で1つずつPodを実行
- **control-plane Taint**: `node-role.kubernetes.io/control-plane:NoSchedule` がデフォルトで設定
- DaemonSetがcontrol-planeで動作しないのは、このTaintへのTolerationがないため
- 関連: [04_ノード管理.md](CKA特化知識/04_ノード管理.md)

#### Step 1: 原因調査 - DaemonSetのPod状態確認

```bash
kubectl get pods -n monitoring -o wide
```

**出力例:**
```
NAME                  READY   STATUS    RESTARTS   AGE   IP           NODE
node-exporter-xxxxx   1/1     Running   0          1m    10.244.1.2   cka-worker
node-exporter-yyyyy   1/1     Running   0          1m    10.244.2.3   cka-worker2
```

control-planeにはPodがない。

#### Step 2: control-planeのTaintを確認

```bash
kubectl describe node cka-control-plane | grep -A 5 Taints
```

**出力例:**
```
Taints:             node-role.kubernetes.io/control-plane:NoSchedule
```

**なぜ?**
control-planeノードには、ユーザーワークロードが配置されないようにデフォルトでTaintが設定されている。
DaemonSetでもこのTaintを許容しないとcontrol-planeでは動作しない。

#### Step 3: DaemonSetにTolerationを追加

```bash
kubectl edit daemonset node-exporter -n monitoring
```

`spec.template.spec` に以下を追加:

```yaml
spec:
  template:
    spec:
      tolerations:
      - key: "node-role.kubernetes.io/control-plane"
        operator: "Exists"
        effect: "NoSchedule"
      containers:
      - name: exporter
        ...
```

**なぜ?**
- `key: node-role.kubernetes.io/control-plane`: control-planeのTaintキー
- `operator: Exists`: 値は問わない（キーが存在すれば許容）
- `effect: NoSchedule`: この効果のTaintを許容

**別解: patchコマンドで追加**

```bash
kubectl patch daemonset node-exporter -n monitoring --type='json' -p='[
  {
    "op": "add",
    "path": "/spec/template/spec/tolerations",
    "value": [
      {
        "key": "node-role.kubernetes.io/control-plane",
        "operator": "Exists",
        "effect": "NoSchedule"
      }
    ]
  }
]'
```

#### 確認方法

```bash
kubectl get pods -n monitoring -o wide
```

**期待する出力:**
```
NAME                  READY   STATUS    RESTARTS   AGE   IP           NODE
node-exporter-xxxxx   1/1     Running   0          2m    10.244.1.2   cka-worker
node-exporter-yyyyy   1/1     Running   0          2m    10.244.2.3   cka-worker2
node-exporter-zzzzz   1/1     Running   0          30s   10.244.0.4   cka-control-plane
```

全ノード（control-plane含む）でPodが実行されていることを確認。

#### DaemonSetでよく使うToleration設定

```yaml
# 全てのTaintを許容（監視系でよく使用）
tolerations:
- operator: "Exists"

# control-planeのみ許容
tolerations:
- key: "node-role.kubernetes.io/control-plane"
  operator: "Exists"
  effect: "NoSchedule"

# 特定のTaintのみ許容
tolerations:
- key: "dedicated"
  operator: "Equal"
  value: "monitoring"
  effect: "NoSchedule"
```

#### よくあるミス

| ミス | 症状 | 対処法 |
|-----|-----|-------|
| Tolerationの場所を間違える | 反映されない | `spec.template.spec.tolerations`に配置 |
| keyのtypo | Tolerationが効かない | `node-role.kubernetes.io/control-plane`を正確に |
| effectの不一致 | Tolerationが効かない | Taintと同じeffectを指定 |

---------------------------------------------------------


=========================================================
問題5
=========================================================
環境準備

次のコマンドを実行して、問題に必要なリソースを作成して下さい。

```bash
kubectl apply -f test/resources/cka/q5-storage.yaml
```

問題

storage-test名前空間には、cka-pvc PersistentVolumeClaimが作成されていますが、STATUSがPendingのままBoundになりません。また、cka-pv PersistentVolumeはAvailableの状態です。

以下のタスクを実行して下さい。



1. cka-pvcがBoundにならない原因を調査して下さい。



2. cka-pvcを修正し、cka-pvとバインドされるようにして下さい。
   なお、cka-pvは変更しないで下さい。



3. cka-pvcのSTATUSがBoundになっていることを確認して下さい。

---------------------------------------------------------

### 解答

#### 理解すべきポイント
- **PersistentVolume (PV)**: クラスタレベルのストレージリソース（管理者が作成）
- **PersistentVolumeClaim (PVC)**: ユーザーがストレージを要求する（Namespaced）
- **バインド条件**: storageClassName, accessModes, capacity が一致する必要がある
- PVCがPendingの場合、上記3つのいずれかが不一致

#### Step 1: 原因調査 - PVとPVCの状態確認

```bash
# PV確認
kubectl get pv cka-pv

# PVC確認
kubectl get pvc -n storage-test cka-pvc
```

**出力例:**
```
NAME     CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS      CLAIM   STORAGECLASS   REASON   AGE
cka-pv   1Gi        RWO            Retain           Available           manual                  1m

NAME      STATUS    VOLUME   CAPACITY   ACCESS MODES   STORAGECLASS   AGE
cka-pvc   Pending                                      wrong-class    1m
```

**分析:**
- PVのSTATUSは`Available`（バインド待ち）
- PVCのSTATUSは`Pending`（マッチするPVがない）
- **storageClassName不一致**: PVは`manual`、PVCは`wrong-class`

#### Step 2: 詳細確認

```bash
# PVの詳細
kubectl describe pv cka-pv | grep -A 2 "StorageClass"

# PVCの詳細
kubectl describe pvc -n storage-test cka-pvc | grep -A 2 "StorageClass"
```

**出力例:**
```
StorageClass:      manual

StorageClass:      wrong-class
```

#### Step 3: PVCのstorageClassNameを修正

PVCはイミュータブルフィールドが多いため、削除→再作成が必要:

```bash
# 現在のPVCをYAML出力
kubectl get pvc -n storage-test cka-pvc -o yaml > /tmp/cka-pvc.yaml

# 削除
kubectl delete pvc -n storage-test cka-pvc
```

`/tmp/cka-pvc.yaml` を編集:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: cka-pvc
  namespace: storage-test
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
  storageClassName: manual  # wrong-class → manual に修正
```

```bash
kubectl apply -f /tmp/cka-pvc.yaml
```

**出力例:**
```
persistentvolumeclaim/cka-pvc created
```

**なぜ?**
- `storageClassName`はPVとPVCで一致する必要がある
- 今回はPVを変更不可のため、PVCを修正

#### 確認方法

```bash
kubectl get pv,pvc -n storage-test
```

**期待する出力:**
```
NAME                      CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                   STORAGECLASS   AGE
persistentvolume/cka-pv   1Gi        RWO            Retain           Bound    storage-test/cka-pvc    manual         5m

NAME                            STATUS   VOLUME   CAPACITY   ACCESS MODES   STORAGECLASS   AGE
persistentvolumeclaim/cka-pvc   Bound    cka-pv   1Gi        RWO            manual         30s
```

両方とも`Bound`になっていることを確認。

#### PV/PVCバインドの条件まとめ

| 条件 | PV設定 | PVC設定 | 一致要件 |
|-----|-------|--------|---------|
| storageClassName | `manual` | `manual` | 完全一致 |
| accessModes | `ReadWriteOnce` | `ReadWriteOnce` | 完全一致 |
| capacity | `1Gi` | `1Gi`以下 | PV >= PVC |

#### よくあるミス

| ミス | 症状 | 対処法 |
|-----|-----|-------|
| storageClassName不一致 | PVC Pending | 両方を同じ名前に |
| accessModes不一致 | PVC Pending | 両方を同じモードに |
| capacity不足 | PVC Pending | PV >= PVCの要求 |
| PVCを直接edit | エラー | 削除→再作成 |

---------------------------------------------------------


=========================================================
問題6
=========================================================
環境準備

次のコマンドを実行して、問題に必要なリソースを作成して下さい。

```bash
kubectl apply -f test/resources/cka/q6-resourcequota.yaml
```

問題

quota-test名前空間には、compute-quota ResourceQuotaが設定されています。quota-app Deploymentが作成されていますが、Podが起動できていません。

以下のタスクを実行して下さい。



1. quota-app DeploymentのPodが作成されない原因を調査して下さい。
   ヒント: `kubectl describe` でDeploymentとReplicaSetのイベントを確認して下さい。



2. ResourceQuotaの制限内でPodが作成されるよう、quota-app Deploymentを修正して下さい。
   コンテナには以下のリソースを設定して下さい：
   - requests.cpu: 100m
   - requests.memory: 64Mi
   - limits.cpu: 200m
   - limits.memory: 128Mi



3. quota-app DeploymentのPodが正常に起動していることを確認して下さい。

---------------------------------------------------------

### 解答

#### 理解すべきポイント
- **ResourceQuota**: Namespace内のリソース使用量を制限
- QuotaにCPU/メモリ制限がある場合、Podには必ず`resources`を設定する必要がある
- `requests`/`limits`がないPodはQuotaでブロックされる

#### Step 1: 原因調査 - Deployment/ReplicaSetのイベント確認

```bash
# Deploymentの状態
kubectl get deploy -n quota-test quota-app

# ReplicaSetの状態
kubectl get rs -n quota-test

# ReplicaSetのイベント確認
kubectl describe rs -n quota-test
```

**出力例:**
```
NAME                   DESIRED   CURRENT   READY   AGE
quota-app              3         0         0       1m

NAME                          DESIRED   CURRENT   READY   AGE
quota-app-xxxxxxxxxx          3         0         0       1m

Events:
  Type     Reason        Age   From                   Message
  ----     ------        ----  ----                   -------
  Warning  FailedCreate  1m    replicaset-controller  Error creating: pods "quota-app-xxxxxxxxxx-xxxxx" is forbidden: failed quota: compute-quota: must specify limits.cpu for: nginx; limits.memory for: nginx; requests.cpu for: nginx; requests.memory for: nginx
```

**原因:**
ResourceQuotaが設定されている環境では、Podに`requests`と`limits`を明示する必要がある。

#### Step 2: ResourceQuotaの確認

```bash
kubectl describe resourcequota compute-quota -n quota-test
```

**出力例:**
```
Name:            compute-quota
Namespace:       quota-test
Resource         Used  Hard
--------         ----  ----
limits.cpu       0     1
limits.memory    0     512Mi
pods             0     5
requests.cpu     0     500m
requests.memory  0     256Mi
```

#### Step 3: Deploymentにリソース設定を追加

```bash
kubectl edit deploy quota-app -n quota-test
```

`spec.template.spec.containers[]` にresourcesを追加:

```yaml
spec:
  template:
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
        resources:
          requests:
            cpu: "100m"
            memory: "64Mi"
          limits:
            cpu: "200m"
            memory: "128Mi"
```

**別解: patchコマンドで修正**

```bash
kubectl patch deploy quota-app -n quota-test --type='json' -p='[
  {
    "op": "add",
    "path": "/spec/template/spec/containers/0/resources",
    "value": {
      "requests": {
        "cpu": "100m",
        "memory": "64Mi"
      },
      "limits": {
        "cpu": "200m",
        "memory": "128Mi"
      }
    }
  }
]'
```

**出力例:**
```
deployment.apps/quota-app patched
```

**なぜ?**
- `requests`: Podがスケジュールされるために必要な最小リソース
- `limits`: Podが使用できる最大リソース
- Quotaが設定されている場合、両方を指定しないとPod作成がブロックされる

#### 確認方法

```bash
kubectl get pods -n quota-test
```

**期待する出力:**
```
NAME                         READY   STATUS    RESTARTS   AGE
quota-app-xxxxxxxxxx-xxxxx   1/1     Running   0          30s
quota-app-xxxxxxxxxx-yyyyy   1/1     Running   0          30s
quota-app-xxxxxxxxxx-zzzzz   1/1     Running   0          30s
```

```bash
# Quota使用量確認
kubectl describe resourcequota compute-quota -n quota-test
```

**出力例:**
```
Resource         Used   Hard
--------         ----   ----
limits.cpu       600m   1
limits.memory    384Mi  512Mi
pods             3      5
requests.cpu     300m   500m
requests.memory  192Mi  256Mi
```

#### よくあるミス

| ミス | 症状 | 対処法 |
|-----|-----|-------|
| requestsのみ設定 | Pod作成失敗 | limitsも設定 |
| limitsのみ設定 | Pod作成失敗 | requestsも設定 |
| Quotaを超える値 | Pod作成失敗 | Quota内の値に調整 |
| 単位ミス（m, Mi等） | 予期しない動作 | CPU: m(ミリコア), メモリ: Mi(メビバイト) |

---------------------------------------------------------


=========================================================
問題7
=========================================================
環境準備

次のコマンドを実行して、問題に必要なリソースを作成して下さい。

```bash
kubectl apply -f test/resources/cka/q7-service-troubleshoot.yaml
```

問題

svc-debug名前空間には、backend Podとbackend-svc Serviceが作成されています。しかし、Serviceを経由してPodに接続することができません。

以下のタスクを実行して下さい。



1. backend-svc ServiceにEndpointが存在しない原因を調査して下さい。
   ヒント: `kubectl get endpoints` と Pod/Service のラベルを確認して下さい。



2. backend-svc Serviceのselectorを修正し、backend Podに接続できるようにして下さい。
   なお、backend Podは変更しないで下さい。



3. 修正後、以下のコマンドでServiceが正しくPodに接続できることを確認して下さい：
   ```bash
   kubectl run test-pod --rm -it --image=busybox --restart=Never -n svc-debug -- wget -qO- backend-svc
   ```

---------------------------------------------------------

### 解答

#### 理解すべきポイント
- **Service**: PodへのロードバランサとDNS名を提供
- **Selector**: Serviceがどのpodにトラフィックを転送するかを決定
- **Endpoints**: Serviceに紐付いたPodのIPリスト
- Serviceにエンドポイントがない = Selectorがどのpodにもマッチしない
- 関連: [06_トラブルシューティング.md](CKA特化知識/06_トラブルシューティング.md)

#### Step 1: 原因調査 - EndpointsとPod/Serviceのラベル確認

```bash
# Endpointsの確認
kubectl get endpoints -n svc-debug backend-svc
```

**出力例:**
```
NAME          ENDPOINTS   AGE
backend-svc   <none>      1m
```

エンドポイントが空 = SelectorがPodにマッチしていない。

#### Step 2: Pod/Serviceのラベル比較

```bash
# Podのラベル確認
kubectl get pod -n svc-debug backend --show-labels

# Serviceのセレクタ確認
kubectl describe svc -n svc-debug backend-svc | grep -A 3 Selector
```

**出力例:**
```
NAME      READY   STATUS    RESTARTS   AGE   LABELS
backend   1/1     Running   0          1m    app=backend,tier=api

Selector:          app=backend-app,tier=web
```

**分析:**
- Pod: `app=backend, tier=api`
- Service Selector: `app=backend-app, tier=web`
- 両方とも不一致！

#### Step 3: Serviceのselectorを修正

```bash
kubectl edit svc backend-svc -n svc-debug
```

selectorを修正:

```yaml
spec:
  selector:
    app: backend      # backend-app → backend
    tier: api         # web → api
  ports:
  - port: 80
    targetPort: 80
```

**別解: patchコマンドで修正**

```bash
kubectl patch svc backend-svc -n svc-debug --type='json' -p='[
  {"op": "replace", "path": "/spec/selector/app", "value": "backend"},
  {"op": "replace", "path": "/spec/selector/tier", "value": "api"}
]'
```

**出力例:**
```
service/backend-svc patched
```

**なぜ?**
ServiceのselectorはPodのlabelsと完全一致する必要がある（指定したキー全て）。

#### 確認方法

```bash
# Endpointsが作成されたことを確認
kubectl get endpoints -n svc-debug backend-svc
```

**期待する出力:**
```
NAME          ENDPOINTS        AGE
backend-svc   10.244.1.5:80    2m
```

```bash
# 接続テスト
kubectl run test-pod --rm -it --image=busybox --restart=Never -n svc-debug -- wget -qO- backend-svc
```

**期待する出力:**
```
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
...
```

#### Serviceトラブルシューティングフロー

```
1. kubectl get endpoints → 空？
   ├── 空の場合 → Selectorの確認
   │   └── kubectl get pod --show-labels
   │   └── kubectl describe svc | grep Selector
   └── IPがある場合 → 次へ

2. Pod自体が動作中？
   └── kubectl get pods

3. targetPortは正しい？
   └── kubectl describe svc
```

#### よくあるミス

| ミス | 症状 | 対処法 |
|-----|-----|-------|
| Selectorのkey不一致 | Endpoints空 | Podのlabelsに合わせる |
| Selectorのvalue不一致 | Endpoints空 | Podのlabelsに合わせる |
| targetPort間違い | 接続できない | Podのコンテナポートに合わせる |
| Podを修正してしまう | 問題の指示違反 | Serviceのみ修正 |

---------------------------------------------------------


=========================================================
問題8
=========================================================
環境準備

次のコマンドを実行して、問題に必要なリソースを作成して下さい。

```bash
kubectl apply -f test/resources/cka/q8-dns-troubleshoot.yaml
```

問題

dns-test名前空間には、dns-client Pod、test-svc Service、test-pod Podが作成されています。

以下のタスクを実行し、DNS解決のトラブルシューティングを行って下さい。



1. dns-client Podから以下のDNS名が解決できることを確認して下さい：
   - test-svc.dns-test.svc.cluster.local
   - kubernetes.default.svc.cluster.local

   ```bash
   kubectl exec -n dns-test dns-client -- nslookup test-svc.dns-test.svc.cluster.local
   ```



2. CoreDNS Podが正常に動作していることを確認して下さい。
   ヒント: `kube-system` 名前空間のCoreDNS関連リソースを確認して下さい。



3. dns-client Podの /etc/resolv.conf の内容を確認し、DNSサーバーのIPアドレスがCoreDNS ServiceのClusterIPと一致していることを確認して下さい。

---------------------------------------------------------

### 解答

#### 理解すべきポイント
- **CoreDNS**: Kubernetes内部のDNSサーバー（kube-system namespaceで動作）
- **Service FQDN**: `<service>.<namespace>.svc.cluster.local`
- **/etc/resolv.conf**: PodのDNS設定（kubeletが自動設定）
- 関連: [06_トラブルシューティング.md](CKA特化知識/06_トラブルシューティング.md)

#### Step 1: DNS解決テスト

```bash
# test-svc の名前解決
kubectl exec -n dns-test dns-client -- nslookup test-svc.dns-test.svc.cluster.local
```

**期待する出力:**
```
Server:    10.96.0.10
Address 1: 10.96.0.10 kube-dns.kube-system.svc.cluster.local

Name:      test-svc.dns-test.svc.cluster.local
Address 1: 10.96.xxx.xxx test-svc.dns-test.svc.cluster.local
```

```bash
# kubernetes API server の名前解決
kubectl exec -n dns-test dns-client -- nslookup kubernetes.default.svc.cluster.local
```

**期待する出力:**
```
Server:    10.96.0.10
Address 1: 10.96.0.10 kube-dns.kube-system.svc.cluster.local

Name:      kubernetes.default.svc.cluster.local
Address 1: 10.96.0.1 kubernetes.default.svc.cluster.local
```

**なぜ?**
- `test-svc.dns-test.svc.cluster.local`: 作成したServiceのFQDN
- `kubernetes.default.svc.cluster.local`: K8s API ServerのService（常に存在）

#### Step 2: CoreDNS Podの確認

```bash
# CoreDNS Podの状態
kubectl get pods -n kube-system -l k8s-app=kube-dns
```

**期待する出力:**
```
NAME                       READY   STATUS    RESTARTS   AGE
coredns-xxxxxxxxxx-xxxxx   1/1     Running   0          30m
coredns-xxxxxxxxxx-yyyyy   1/1     Running   0          30m
```

```bash
# CoreDNS Deploymentの確認
kubectl get deploy -n kube-system coredns
```

**期待する出力:**
```
NAME      READY   UP-TO-DATE   AVAILABLE   AGE
coredns   2/2     2            2           30m
```

**なぜ?**
CoreDNSが正常に動作していないとDNS解決が失敗する。

#### Step 3: resolv.confとCoreDNS Service IPの一致確認

```bash
# dns-client Pod の /etc/resolv.conf
kubectl exec -n dns-test dns-client -- cat /etc/resolv.conf
```

**期待する出力:**
```
nameserver 10.96.0.10
search dns-test.svc.cluster.local svc.cluster.local cluster.local
options ndots:5
```

```bash
# CoreDNS (kube-dns) Service の ClusterIP
kubectl get svc -n kube-system kube-dns
```

**期待する出力:**
```
NAME       TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)                  AGE
kube-dns   ClusterIP   10.96.0.10   <none>        53/UDP,53/TCP,9153/TCP   30m
```

**確認:**
- resolv.confの`nameserver`: `10.96.0.10`
- kube-dns ServiceのCLUSTER-IP: `10.96.0.10`
- **一致していればOK!**

**なぜ?**
kubeletがPodを作成する際に、kube-dns ServiceのClusterIPを/etc/resolv.confに自動設定する。

#### DNS関連のトラブルシューティングコマンド

```bash
# CoreDNSのログ確認
kubectl logs -n kube-system -l k8s-app=kube-dns

# CoreDNSの設定（ConfigMap）
kubectl get configmap -n kube-system coredns -o yaml

# DNS解決テスト（詳細）
kubectl exec -n dns-test dns-client -- nslookup -debug test-svc

# 短縮名での解決（search ドメイン使用）
kubectl exec -n dns-test dns-client -- nslookup test-svc
```

#### DNS名の形式

| 形式 | 例 | 説明 |
|-----|---|-----|
| FQDN | `test-svc.dns-test.svc.cluster.local` | 完全修飾名 |
| 同一NS内 | `test-svc` | search ドメインで解決 |
| 別NS | `test-svc.dns-test` | namespace指定 |

#### よくあるミス

| ミス | 症状 | 対処法 |
|-----|-----|-------|
| CoreDNS未起動 | 全てのDNS解決失敗 | CoreDNS Podの状態確認 |
| Service名typo | 名前解決失敗 | `kubectl get svc`で確認 |
| Namespace間違い | 名前解決失敗 | FQDNで正確に指定 |

---------------------------------------------------------


=========================================================
問題9
=========================================================
環境準備

次のコマンドを実行して、問題に必要なリソースを作成して下さい。

```bash
kubectl apply -f test/resources/cka/q9-node-selector.yaml
```

問題

placement名前空間には、gpu-pod Podが作成されていますが、STATUSがPendingのままです。このPodにはnodeSelectorが設定されており、特定のラベルを持つノードにのみスケジュールされます。

以下のタスクを実行して下さい。



1. gpu-podがPendingになっている原因を調査して下さい。



2. 1つのworkerノードを選択し、gpu-podのnodeSelectorに一致するラベルを付与して下さい：
   - gpu=true
   - zone=us-west-1a



3. gpu-podがラベルを付与したノードで実行されていることを確認して下さい。

---------------------------------------------------------

### 解答

#### 理解すべきポイント
- **nodeSelector**: 特定のラベルを持つノードにのみPodを配置
- nodeSelectorで指定したラベルが全てマッチするノードがないとPodはPending
- ラベルはkey=value形式でノードに付与
- 関連: [04_ノード管理.md](CKA特化知識/04_ノード管理.md)

#### Step 1: 原因調査 - PodがPendingの理由確認

```bash
# Podの状態確認
kubectl get pod -n placement gpu-pod
```

**出力例:**
```
NAME      READY   STATUS    RESTARTS   AGE
gpu-pod   0/1     Pending   0          1m
```

```bash
# 詳細イベント確認
kubectl describe pod -n placement gpu-pod | grep -A 5 Events
```

**出力例:**
```
Events:
  Type     Reason            Age   From               Message
  ----     ------            ----  ----               -------
  Warning  FailedScheduling  1m    default-scheduler  0/3 nodes are available: 3 node(s) didn't match Pod's node affinity/selector.
```

**分析:**
nodeSelectorで指定したラベルを持つノードが存在しないためPending。

#### Step 2: PodのnodeSelectorを確認

```bash
kubectl get pod -n placement gpu-pod -o yaml | grep -A 5 nodeSelector
```

**出力例:**
```yaml
  nodeSelector:
    gpu: "true"
    zone: us-west-1a
```

#### Step 3: ノードの現在のラベル確認

```bash
kubectl get nodes --show-labels
```

**出力例:**
```
NAME                 STATUS   ROLES           AGE   VERSION   LABELS
cka-control-plane    Ready    control-plane   30m   v1.30.0   kubernetes.io/hostname=cka-control-plane,...
cka-worker           Ready    <none>          30m   v1.30.0   kubernetes.io/hostname=cka-worker,...
cka-worker2          Ready    <none>          30m   v1.30.0   kubernetes.io/hostname=cka-worker2,...
```

`gpu`や`zone`ラベルがないことを確認。

#### Step 4: workerノードにラベルを付与

```bash
# cka-worker に2つのラベルを付与
kubectl label nodes cka-worker gpu=true zone=us-west-1a
```

**出力例:**
```
node/cka-worker labeled
```

**別解: 複数ラベルを一度に付与**

```bash
kubectl label nodes cka-worker gpu=true zone=us-west-1a
```

**なぜ?**
nodeSelectorで指定された全てのラベルがノードに存在する必要がある。
ラベルが揃うとスケジューラがPodを自動的に配置する。

#### 確認方法

```bash
# Podの状態確認（Running になるまで待つ）
kubectl get pod -n placement gpu-pod -o wide
```

**期待する出力:**
```
NAME      READY   STATUS    RESTARTS   AGE   IP           NODE
gpu-pod   1/1     Running   0          2m    10.244.1.5   cka-worker
```

```bash
# ノードのラベル確認
kubectl get node cka-worker --show-labels | grep -E "gpu|zone"
```

**期待する出力:**
```
gpu=true,zone=us-west-1a,...
```

#### ラベル操作コマンドまとめ

```bash
# ラベル追加
kubectl label nodes <node> key=value

# ラベル更新（--overwrite必須）
kubectl label nodes <node> key=newvalue --overwrite

# ラベル削除（末尾に-）
kubectl label nodes <node> key-

# 特定ラベルを持つノード一覧
kubectl get nodes -l gpu=true
```

#### よくあるミス

| ミス | 症状 | 対処法 |
|-----|-----|-------|
| ラベル1つだけ付与 | まだPending | 全てのラベルを付与 |
| ラベル値の不一致 | Pending | `"true"`と`true`の違いに注意 |
| control-planeにラベル付与 | Taintで弾かれる | workerノードに付与 |
| ラベルkey typo | Pending | 正確に指定 |

---------------------------------------------------------


=========================================================
問題10
=========================================================
環境準備

次のコマンドを実行して、問題に必要なリソースを作成して下さい。

```bash
kubectl apply -f test/resources/cka/q10-events.yaml
```

問題

events-test名前空間には、複数のリソースが作成されていますが、いくつかのPodが正常に起動できていません。

以下のタスクを実行し、クラスタイベントを使用してトラブルシューティングを行って下さい。



1. events-test名前空間のイベントを確認し、問題が発生しているリソースを特定して下さい。
   ```bash
   kubectl get events -n events-test --sort-by='.lastTimestamp'
   ```



2. 以下の各Podについて、起動失敗の原因を特定し、/tmp/events-report.txt に記載して下さい：
   - failing-pod: [原因を記載]
   - resource-hog Deploymentのpod: [原因を記載]
   - config-error: [原因を記載]



3. failing-podを修正して正常に起動させて下さい。
   ヒント: 正しいイメージタグは `nginx:alpine` です。

---------------------------------------------------------

### 解答

#### 理解すべきポイント
- **Events**: クラスタ内で発生したイベントを記録（トラブルシューティングの第一歩）
- イベントは時系列で確認可能（`--sort-by='.lastTimestamp'`）
- Pod失敗の主な原因: イメージ問題、リソース不足、設定エラー
- 関連: [06_トラブルシューティング.md](CKA特化知識/06_トラブルシューティング.md)

#### Step 1: イベント確認

```bash
kubectl get events -n events-test --sort-by='.lastTimestamp'
```

**出力例:**
```
LAST SEEN   TYPE      REASON              OBJECT                           MESSAGE
1m          Warning   FailedScheduling    pod/resource-hog-xxxxx-yyyyy     0/3 nodes are available: 3 Insufficient memory.
1m          Warning   Failed              pod/failing-pod                   Failed to pull image "nginx:nonexistent-tag-12345"
1m          Warning   Failed              pod/config-error                  Error: configmap "missing-config" not found
```

#### Step 2: 各Podの原因を特定してレポート作成

```bash
# 各Podの詳細確認
kubectl describe pod -n events-test failing-pod
kubectl describe pod -n events-test config-error
kubectl describe rs -n events-test  # resource-hogのReplicaSet
```

**レポート作成:**

```bash
cat > /tmp/events-report.txt << 'EOF'
CKA Events トラブルシューティングレポート
==========================================

1. failing-pod
   原因: イメージタグ不正
   詳細: nginx:nonexistent-tag-12345 というイメージタグは存在しない
   エラー: ImagePullBackOff / ErrImagePull
   対処: 正しいタグ（nginx:alpine）に修正

2. resource-hog DeploymentのPod
   原因: リソース要求過大
   詳細: memory: 10Gi, cpu: 10 は利用可能なリソースを超過
   エラー: FailedScheduling - Insufficient memory/cpu
   対処: リソース要求を適切な値に減らす

3. config-error
   原因: 存在しないConfigMapを参照
   詳細: missing-config ConfigMapが存在しない
   エラー: CreateContainerConfigError
   対処: ConfigMapを作成するか、参照を削除
EOF
```

#### Step 3: failing-podを修正

Podを削除して正しいイメージで再作成:

```bash
# 現在のPod定義を取得
kubectl get pod -n events-test failing-pod -o yaml > /tmp/failing-pod.yaml

# Pod削除
kubectl delete pod -n events-test failing-pod
```

`/tmp/failing-pod.yaml` を編集:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: failing-pod
  namespace: events-test
spec:
  containers:
  - name: app
    image: nginx:alpine  # nginx:nonexistent-tag-12345 → nginx:alpine
    ports:
    - containerPort: 80
```

```bash
kubectl apply -f /tmp/failing-pod.yaml
```

**別解: kubectl set imageコマンド（ただしPodには使用不可、Deploymentのみ）**

Podの場合は削除→再作成が必要。

#### 確認方法

```bash
kubectl get pod -n events-test failing-pod
```

**期待する出力:**
```
NAME          READY   STATUS    RESTARTS   AGE
failing-pod   1/1     Running   0          30s
```

#### 各エラータイプと対処法まとめ

| エラー | 原因 | 確認コマンド | 対処法 |
|-------|-----|------------|-------|
| ImagePullBackOff | イメージ取得失敗 | `kubectl describe pod` | イメージ名/タグを修正 |
| ErrImagePull | イメージ存在しない | `kubectl describe pod` | イメージ名/タグを修正 |
| FailedScheduling | スケジュール不可 | `kubectl describe pod` | リソース/ノード確認 |
| CreateContainerConfigError | 設定エラー | `kubectl describe pod` | ConfigMap/Secret確認 |
| CrashLoopBackOff | コンテナ異常終了 | `kubectl logs` | アプリログ確認 |

#### イベント確認のベストプラクティス

```bash
# 特定Namespace
kubectl get events -n <namespace> --sort-by='.lastTimestamp'

# 全Namespace
kubectl get events -A --sort-by='.lastTimestamp'

# 特定Podのイベント
kubectl describe pod <pod> -n <namespace> | grep -A 20 Events

# Warningのみ
kubectl get events -n <namespace> --field-selector type=Warning
```

#### よくあるミス

| ミス | 症状 | 対処法 |
|-----|-----|-------|
| Pod editで修正しようとする | イメージはイミュータブル | 削除→再作成 |
| レポート作成忘れ | 問題の要件未達 | /tmp/events-report.txt作成 |
| イメージタグのtypo | まだImagePullBackOff | `nginx:alpine`を正確に |

---------------------------------------------------------


=========================================================
CKA 実技問題 完了
=========================================================

## 重要コマンド一覧

```bash
# Node メンテナンス
kubectl cordon <node>
kubectl drain <node> --ignore-daemonsets --delete-emptydir-data
kubectl uncordon <node>

# RBAC
kubectl create clusterrole <name> --verb=get,list,watch --resource=pods,nodes
kubectl create clusterrolebinding <name> --clusterrole=<role> --serviceaccount=<ns>:<sa>

# Taint/Toleration
kubectl taint nodes <node> key=value:NoSchedule
kubectl taint nodes <node> key=value:NoSchedule-  # 削除

# Node Labels
kubectl label nodes <node> key=value
kubectl label nodes <node> key-  # 削除

# トラブルシューティング
kubectl describe pod <pod> -n <ns>
kubectl get events -n <ns> --sort-by='.lastTimestamp'
kubectl logs <pod> -n <ns>
kubectl exec -it <pod> -n <ns> -- <command>
```
