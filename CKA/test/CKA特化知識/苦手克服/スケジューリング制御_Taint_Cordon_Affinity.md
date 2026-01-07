# Taint / Toleration / Cordon / Drain / Affinity 完全整理

## 全体像：誰が何を制御するか

### 英単語の意味

| 用語 | 英語の意味 | K8s での意味 |
|------|-----------|-------------|
| **Taint** | 汚れ、汚点 | Node に「汚れ」をつけて Pod を寄せ付けない |
| **Toleration** | 耐性、許容 | 「汚れ」を我慢できる＝配置OK |
| **Cordon** | 非常線、立入禁止線 | 警察の黄色テープ → 新規 Pod 立入禁止 |
| **Drain** | 排水する、流し出す | 水を抜く → Pod を退避させる |
| **Affinity** | 親和性、好み | 「この Node が好き」という Pod の希望 |

```
┌─────────────────────────────────────────────────────────────────┐
│                     Pod のスケジューリング制御                    │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   【Node 側から制御】           【Pod 側から制御】                │
│                                                                 │
│   ┌─────────────┐              ┌─────────────┐                 │
│   │   Taint     │──────────────│ Toleration  │                 │
│   │   (汚れ)    │   対になる    │   (耐性)    │                 │
│   └─────────────┘              └─────────────┘                 │
│                                                                 │
│   ┌─────────────┐              ┌─────────────┐                 │
│   │   Cordon    │              │  Affinity   │                 │
│   │ (非常線)    │              │  (親和性)   │                 │
│   └─────────────┘              └─────────────┘                 │
│                                                                 │
│   ┌─────────────┐                                              │
│   │   Drain     │                                              │
│   │  (排水)     │                                              │
│   └─────────────┘                                              │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## 1. Taint & Toleration（ペアで覚える）

### 概念

| 用語 | 対象 | 意味 | 日本語イメージ |
|------|------|------|----------------|
| **Taint** | Node | 「汚れ」をつける | 「お断り」の札 |
| **Toleration** | Pod | 「汚れ」を許容する | 「お断りでも入れます」パス |

### Taint の Effect（3種類）

```
NoSchedule        : 新規 Pod をスケジュールしない（既存は残る）
PreferNoSchedule  : できれば避ける（弱い制約）
NoExecute         : 新規拒否 + 既存 Pod も退避させる（強い制約）
```

### コマンド

```bash
# Taint を付与
kubectl taint nodes <node> key=value:NoSchedule

# Taint を削除（末尾に - をつける）
kubectl taint nodes <node> key=value:NoSchedule-

# Taint を確認
kubectl describe node <node> | grep -A5 Taints
```

### Toleration の書き方（Pod spec）

```yaml
spec:
  tolerations:
  # 完全一致
  - key: "key"
    operator: "Equal"
    value: "value"
    effect: "NoSchedule"

  # key だけ一致（value は何でもOK）
  - key: "key"
    operator: "Exists"
    effect: "NoSchedule"

  # 全ての Taint を許容（危険！）
  - operator: "Exists"
```

### 典型的な使用例

```bash
# control-plane Node には通常この Taint がある
node-role.kubernetes.io/control-plane:NoSchedule

# GPU Node 用
kubectl taint nodes gpu-node gpu=true:NoSchedule
```

---

## 2. Cordon / Uncordon / Drain（運用3兄弟）

### 比較表

| コマンド | 新規 Pod | 既存 Pod | 用途 |
|----------|----------|----------|------|
| `cordon` | ❌ 拒否 | ✅ そのまま | 軽いメンテ準備 |
| `drain` | ❌ 拒否 | ❌ 退避 | 本格メンテ |
| `uncordon` | ✅ 許可 | - | メンテ完了 |

### メンテナンスの流れ

```
通常運用 ──→ cordon ──→ drain ──→ メンテ作業 ──→ uncordon ──→ 通常運用
              │          │                         │
              │          └─ Pod が退避            │
              └─ 新規スケジュール停止              └─ 新規スケジュール再開
```

### コマンド

```bash
# 新規スケジュールを停止（既存 Pod は残る）
kubectl cordon <node>

# Pod を退避させる（+ cordon も実行される）
kubectl drain <node> --ignore-daemonsets --delete-emptydir-data

# スケジュール再開
kubectl uncordon <node>

# Node の状態確認
kubectl get nodes
# NAME     STATUS                     ROLES
# node1    Ready,SchedulingDisabled   <none>  ← cordon/drain 後
```

### drain のオプション（必須暗記）

```bash
kubectl drain <node> \
  --ignore-daemonsets \      # DaemonSet Pod を無視（必須）
  --delete-emptydir-data \   # emptyDir を持つ Pod も削除
  --force \                  # ReplicaSet 管理外の Pod も削除
  --grace-period=30          # 猶予期間（秒）
```

### なぜ --ignore-daemonsets が必要か

```
DaemonSet Pod の特徴：
- 各 Node に必ず1つ存在する
- 退避しても同じ Node に再作成される
- → 退避する意味がない → 無視するしかない
```

---

## 3. Affinity（Pod 側からの希望）

### 種類

```
┌─────────────────────────────────────────────────────────────┐
│                        Affinity                             │
├─────────────────────┬───────────────────────────────────────┤
│   nodeAffinity      │   どの Node に配置したいか            │
├─────────────────────┼───────────────────────────────────────┤
│   podAffinity       │   どの Pod の近くに配置したいか       │
├─────────────────────┼───────────────────────────────────────┤
│   podAntiAffinity   │   どの Pod から離れて配置したいか     │
└─────────────────────┴───────────────────────────────────────┘
```

### nodeAffinity vs nodeSelector

| 機能 | nodeSelector | nodeAffinity |
|------|--------------|--------------|
| 記法 | シンプル | 複雑 |
| 条件 | 完全一致のみ | In, NotIn, Exists, Gt, Lt |
| 強制度 | 必須のみ | 必須 / 優先 を選べる |
| 推奨 | 単純なケース | 複雑な条件 |

### nodeSelector（シンプル版）

```yaml
spec:
  nodeSelector:
    disktype: ssd
    gpu: "true"
```

### nodeAffinity（高機能版）

```yaml
spec:
  affinity:
    nodeAffinity:
      # 必須条件（満たさないとスケジュールされない）
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
        - matchExpressions:
          - key: disktype
            operator: In
            values:
            - ssd
            - nvme

      # 優先条件（できれば従う）
      preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 100
        preference:
          matchExpressions:
          - key: zone
            operator: In
            values:
            - ap-northeast-1a
```

### 長い名前の覚え方

```
requiredDuringSchedulingIgnoredDuringExecution
└─必須──┘└─スケジュール時─┘└─無視─┘└─実行中─┘

「スケジュール時は必須、実行中は無視」
= 一度配置されたら Node のラベルが変わっても退避しない
```

---

## 4. 混乱ポイント整理

### Q: Taint と Cordon の違いは？

| 観点 | Taint | Cordon |
|------|-------|--------|
| 設定対象 | Node | Node |
| 目的 | 特定 Pod だけ許可 | 全 Pod を拒否 |
| 既存 Pod | Effect 次第 | 影響なし |
| 解除方法 | taint ... - | uncordon |
| 用途 | 専用 Node 作成 | メンテナンス |

### Q: Taint と Affinity の違いは？

| 観点 | Taint | Affinity |
|------|-------|----------|
| 視点 | Node から排除 | Pod から希望 |
| デフォルト | 拒否（Toleration 必要） | 許可（条件なければどこでも） |
| 強制力 | 強い（明示的許可必要） | 弱い〜強い（設定次第） |

### Q: Drain と Taint NoExecute の違いは？

| 観点 | drain | Taint NoExecute |
|------|-------|-----------------|
| 操作 | コマンド1発 | Taint 設定 |
| 退避対象 | 全 Pod | Toleration ない Pod |
| 自動 uncordon | なし | Taint 削除で解除 |
| 用途 | 一時的メンテ | 恒久的な排除 |

---

## 5. ユースケース別：配置戦略の選び方

### 「ここに配置したい」系

| ユースケース | 使う機能 | 理由 |
|-------------|---------|------|
| DBはSSDノードに | nodeSelector or nodeAffinity | Podの希望を指定 |
| MLはGPUノードに | nodeSelector + Taint/Toleration | 希望 + 他Podの排除 |
| 高メモリAppは大容量ノードに | nodeAffinity | 複数条件指定可能 |
| WebとDBは同じゾーンに | podAffinity | Pod間の近接配置 |

### 「ここに配置させない」系

| ユースケース | 使う機能 | 理由 |
|-------------|---------|------|
| control-planeに一般Podを置かない | Taint | Nodeから拒否 |
| 専用ノードを作りたい | Taint + Toleration | 許可制にする |
| メンテ中はPodを置かない | Cordon/Drain | 一時的な運用 |
| 同じPodを同じノードに置かない（HA） | podAntiAffinity | 分散配置 |

---

### 実践例1: DB専用ノード（SSD）

```bash
# Step 1: ノードにラベル付け
kubectl label node db-node-01 disktype=ssd

# Step 2: Taintで他のPodを排除（任意）
kubectl taint nodes db-node-01 dedicated=database:NoSchedule
```

```yaml
# Step 3: Pod/Deployment で指定
apiVersion: v1
kind: Pod
metadata:
  name: mysql-pod
spec:
  nodeSelector:
    disktype: ssd
  tolerations:           # Taintを設定した場合に必要
  - key: "dedicated"
    operator: "Equal"
    value: "database"
    effect: "NoSchedule"
  containers:
  - name: mysql
    image: mysql:8.0
```

---

### 実践例2: GPU専用ノード（ML/AI）

```bash
# Step 1: GPUノードにラベル付け
kubectl label node gpu-node-01 accelerator=nvidia-tesla-v100

# Step 2: Taintで一般Podを排除（重要！高価なリソースなので）
kubectl taint nodes gpu-node-01 nvidia.com/gpu=true:NoSchedule
```

```yaml
# Step 3: ML用Podで指定
apiVersion: v1
kind: Pod
metadata:
  name: ml-training
spec:
  nodeSelector:
    accelerator: nvidia-tesla-v100
  tolerations:
  - key: "nvidia.com/gpu"
    operator: "Exists"
    effect: "NoSchedule"
  containers:
  - name: pytorch
    image: pytorch/pytorch:latest
    resources:
      limits:
        nvidia.com/gpu: 1
```

---

### 実践例3: ゾーン分散（HA構成）

```yaml
# 同じDeploymentのPodを異なるゾーンに分散
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
spec:
  replicas: 3
  template:
    spec:
      affinity:
        # 同じAppのPodを同じノードに置かない
        podAntiAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
          - labelSelector:
              matchLabels:
                app: web-app
            topologyKey: "kubernetes.io/hostname"
        # できればap-northeast-1に配置
        nodeAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 100
            preference:
              matchExpressions:
              - key: topology.kubernetes.io/zone
                operator: In
                values:
                - ap-northeast-1a
                - ap-northeast-1c
      containers:
      - name: nginx
        image: nginx
```

---

### パターン早見表

```
┌────────────────────────────────────────────────────────────────┐
│                    配置制御の考え方                             │
├────────────────────────────────────────────────────────────────┤
│                                                                │
│   「このPodをここに置きたい」                                   │
│   └─ nodeSelector / nodeAffinity                               │
│      └─ Pod側から希望を出す                                    │
│                                                                │
│   「このノードを専用にしたい」                                  │
│   └─ Taint + Toleration                                        │
│      └─ Node側で入場制限 + 許可証を持つPodだけ入れる           │
│                                                                │
│   よくある組み合わせ：                                          │
│   ┌─────────────────────────────────────────────────────────┐ │
│   │  nodeSelector（ここに行きたい）                          │ │
│   │       +                                                  │ │
│   │  Taint/Toleration（ここは専用）                          │ │
│   │       =                                                  │ │
│   │  特定ノードに特定Podだけ配置                             │ │
│   └─────────────────────────────────────────────────────────┘ │
│                                                                │
└────────────────────────────────────────────────────────────────┘
```

---

## 6. 試験での使い分けフローチャート

```
Pod を特定 Node に配置したい
├─ 単純なラベル一致 → nodeSelector
└─ 複雑な条件 → nodeAffinity

特定 Node を専用にしたい（他の Pod は排除）
└─ Taint + Toleration

Node をメンテナンスしたい
├─ 軽い作業（既存 Pod は残してOK） → cordon
└─ 重い作業（Pod を退避させたい） → drain
    └─ 完了後 → uncordon

特定 Pod を他の Pod の近くに配置したい
└─ podAffinity

特定 Pod を他の Pod から離したい（HA構成）
└─ podAntiAffinity
```

---

## 6. 暗記用コマンド早見表

```bash
# === Taint ===
kubectl taint nodes <node> key=value:NoSchedule      # 付与
kubectl taint nodes <node> key=value:NoSchedule-     # 削除
kubectl describe node <node> | grep Taints           # 確認

# === Cordon / Drain / Uncordon ===
kubectl cordon <node>                                # 新規拒否
kubectl drain <node> --ignore-daemonsets --delete-emptydir-data  # 退避
kubectl uncordon <node>                              # 再開

# === Node ラベル（Affinity 用）===
kubectl get nodes --show-labels                      # 確認
kubectl label node <node> key=value                  # 付与
kubectl label node <node> key-                       # 削除
```

---

## 7. 実践問題

### 問題1
Node `node01` をメンテナンスのため、新規 Pod のスケジュールを停止し、既存 Pod を全て退避させたい。正しいコマンドは？

<details>
<summary>答え</summary>

```bash
kubectl drain node01 --ignore-daemonsets --delete-emptydir-data
```

※ `cordon` だけでは既存 Pod は退避しない

</details>

### 問題2
GPU を持つ Node に GPU を使う Pod だけを配置したい。どの機能を使うべきか？

<details>
<summary>答え</summary>

**Taint + Toleration**

```bash
# Node 側
kubectl taint nodes gpu-node gpu=true:NoSchedule

# Pod 側（yaml）
tolerations:
- key: "gpu"
  operator: "Equal"
  value: "true"
  effect: "NoSchedule"
```

※ Affinity だけでは「他の Pod が来ない」保証がない

</details>

### 問題3
`kubectl cordon` と `kubectl taint ... :NoSchedule` の違いは？

<details>
<summary>答え</summary>

| cordon | taint NoSchedule |
|--------|------------------|
| 全 Pod を拒否 | Toleration ある Pod は許可 |
| メンテナンス用 | 専用 Node 作成用 |
| uncordon で解除 | taint ... - で解除 |

</details>
