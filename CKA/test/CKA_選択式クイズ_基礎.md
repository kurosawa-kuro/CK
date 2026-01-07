# CKA 非CKAD重複・超基礎問題（厳選）

## ① クラスタ／コントロールプレーン理解（最重要）

### Q1

kube-apiserver が停止した場合、**既存Podで「起きない」ことはどれか**

A. 既存Podが即座に停止する
B. kubectl で新しい Pod を作成できなくなる
C. Controller が Desired State を更新できなくなる
D. 新しい Node の参加ができなくなる

👉 **ポイント**：

* control plane 停止時の *read/write* の影響範囲

---

### Q2

kube-controller-manager の役割として **誤っているもの** はどれか

A. Node の NotReady 判定
B. Replica 数の調整
C. Pod 内コンテナの起動
D. Service Account Token の生成

👉 **ポイント**：

* 「ノード上で何が動くか」との切り分け

---

### Q3

etcd に保存されていない情報はどれか

A. Pod 定義
B. ConfigMap
C. Node の CPU 使用率
D. Secret

👉 **ポイント**：

* etcd = **宣言的状態のみ**

---

## ② ノード・スケジューリング（CKA専用領域）

### Q4

Pod が Node にスケジュール **されない理由として最も直接的なもの** はどれか

A. Node に taint があり、toleration がない
B. Node の kubelet が再起動された
C. Node に Pod が多すぎる
D. Pod の image が存在しない

👉 **ポイント**：

* *スケジューリング失敗* と *Pod起動失敗* の違い

---

### Q5

以下のうち **スケジューラが考慮しない要素** はどれか

A. requests.cpu
B. requests.memory
C. limits.memory
D. NodeSelector

👉 **ポイント**：

* requests と limits の役割分離

---

## ③ クラスタ運用・メンテナンス（CKADでは出ない）

### Q6

ノードを安全にメンテナンスするための **正しい手順** はどれか

A. cordon → drain → 作業 → uncordon
B. drain → cordon → 作業 → uncordon
C. cordon → 作業 → drain → uncordon
D. uncordon → drain → 作業

👉 **ポイント**：

* 試験で**順番問題は確実に出る**

---

### Q7

`kubectl drain` 実行時に **デフォルトで削除されない Pod** はどれか

A. Deployment 管理の Pod
B. ReplicaSet 管理の Pod
C. DaemonSet 管理の Pod
D. Job 管理の Pod

👉 **ポイント**：

* `--ignore-daemonsets` の意味

---

## ④ ネットワーク（Service / DNS / kube-proxy）

### Q8

ClusterIP Service の通信が成立するために **必須なコンポーネント** はどれか

A. CoreDNS
B. kube-proxy
C. ingress-controller
D. CNI Plugin

👉 **ポイント**：

* Service と DNS を分離して理解しているか

---

### Q9

Pod から `my-service.default.svc.cluster.local` が名前解決できない場合、
**最初に疑うべきコンポーネント** はどれか

A. kube-proxy
B. CoreDNS
C. kube-apiserver
D. etcd

👉 **ポイント**：

* 通信障害 vs 名前解決障害

---

## ⑤ ストレージ（CKA頻出・CKAD軽視）

### Q10

PersistentVolume が `Available` のまま `Bound` にならない
**最も多い原因** はどれか

A. PVC の accessModes 不一致
B. Pod が存在しない
C. Node が NotReady
D. StorageClass が default でない

👉 **ポイント**：

* PV ↔ PVC マッチ条件

---

## ⑥ トラブルシューティング基礎（CKAの本質）

### Q11

Pod が `Pending` のままの場合、**最初に確認すべきコマンド** はどれか

A. kubectl logs
B. kubectl describe pod
C. kubectl exec
D. kubectl top pod

👉 **ポイント**：

* 状態別の「初手コマンド」

---

### Q12

Node が `NotReady` の場合、
**Node 上で直接確認すべきプロセス** はどれか

A. kube-proxy
B. kubelet
C. kube-apiserver
D. controller-manager

👉 **ポイント**：

* Node常駐 vs Control Plane常駐

---

## 使い方（重要）

* **全問「なぜそうなるか」を声に出して説明できるか**
* 迷った問題は **CKA本試験で落とす典型**

次のステップとしておすすめは：

1️⃣ **これを実技コマンド問題に変換**
2️⃣ **「選択肢を消す思考ルート」を整理**
3️⃣ **本試験60点→80点ラインの境界問題**

どれをやりますか。
