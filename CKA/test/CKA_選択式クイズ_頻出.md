# CKA 基礎・頻出問題（CKAD非重複）

## ① kubeadm / クラスタアップグレード

### Q1

kubeadm を使用してコントロールプレーンをアップグレードする際、**最初に実行すべきコマンド** はどれか

A. kubeadm upgrade apply v1.xx.x
B. kubeadm upgrade plan
C. apt-get upgrade kubelet
D. kubectl drain controlplane

👉 **ポイント**：

* `upgrade plan` で互換性とアップグレードパスを確認してから実行

---

### Q2

kubeadm upgrade 後、**手動で再起動が必要なコンポーネント** はどれか

A. kube-apiserver
B. kube-scheduler
C. kubelet
D. etcd

👉 **ポイント**：

* Static Pod は自動再起動、kubelet は `systemctl restart kubelet` が必要

---

## ② etcd バックアップ・リストア

### Q3

etcd のスナップショットを取得するコマンドで **必須のオプション** はどれか

A. --data-dir
B. --endpoints
C. --snapshot-file
D. --listen-peer-urls

👉 **ポイント**：

* `etcdctl snapshot save` には `--endpoints`, `--cacert`, `--cert`, `--key` が必要

---

### Q4

etcd スナップショットをリストアした後、**追加で必要な作業** はどれか

A. kube-apiserver を再起動する
B. kubelet を再起動する
C. etcd の --data-dir を新しいパスに変更する
D. CoreDNS を再デプロイする

👉 **ポイント**：

* リストア先は新しいディレクトリ、etcd の起動オプションで `--data-dir` を更新

---

## ③ Static Pod

### Q5

Static Pod のマニフェストファイルの **デフォルトの配置場所** はどれか

A. /etc/kubernetes/manifests
B. /var/lib/kubelet/pods
C. /opt/cni/bin
D. /etc/cni/net.d

👉 **ポイント**：

* kubelet の `--pod-manifest-path` または `staticPodPath` で確認可能

---

### Q6

Static Pod を削除するために **正しい方法** はどれか

A. kubectl delete pod <pod-name>
B. マニフェストファイルを /etc/kubernetes/manifests から削除
C. kubelet を停止する
D. kubectl drain を実行する

👉 **ポイント**：

* Static Pod は kubelet が直接管理、API経由の削除は不可

---

## ④ 証明書・TLS

### Q7

kube-apiserver の証明書の有効期限を確認するコマンドはどれか

A. kubeadm certs check-expiration
B. kubectl get certificates
C. openssl verify /etc/kubernetes/pki/apiserver.crt
D. kubectl describe node

👉 **ポイント**：

* `kubeadm certs check-expiration` で全証明書の期限を一覧表示

---

### Q8

クラスタ証明書の更新で **自動的に更新されないもの** はどれか

A. kube-apiserver の証明書
B. kubelet クライアント証明書
C. 外部 CA で署名した証明書
D. etcd の証明書

👉 **ポイント**：

* kubeadm は自己署名証明書のみ更新、外部 CA は手動

---

## ⑤ kubelet トラブルシューティング

### Q9

Node が NotReady の場合、**Node 上で最初に確認すべきコマンド** はどれか

A. kubectl describe node
B. systemctl status kubelet
C. kubectl get events
D. journalctl -u kube-proxy

👉 **ポイント**：

* Node の問題は kubelet の状態確認が最優先

---

### Q10

kubelet が起動しない場合、**ログを確認するコマンド** はどれか

A. kubectl logs kubelet
B. journalctl -u kubelet
C. cat /var/log/kubelet.log
D. docker logs kubelet

👉 **ポイント**：

* kubelet は systemd サービス、journalctl でログ確認

---

## ⑥ クラスタコンポーネント配置

### Q11

kube-scheduler が停止した場合、**影響を受けないもの** はどれか

A. 新規 Pod の Node 割り当て
B. 既存 Pod の実行継続
C. DaemonSet による新規 Pod 作成
D. ReplicaSet による Pod 再作成

👉 **ポイント**：

* 既存 Pod は影響なし、新規スケジューリングのみ停止

---

### Q12

コントロールプレーンコンポーネントの中で **Node 上で動作するもの** はどれか

A. kube-apiserver
B. kube-scheduler
C. kube-proxy
D. kube-controller-manager

👉 **ポイント**：

* kube-proxy は DaemonSet として全 Node で動作

---

## ⑦ ネットワーク・CNI

### Q13

CNI プラグインの設定ファイルの **デフォルトの配置場所** はどれか

A. /etc/kubernetes/manifests
B. /etc/cni/net.d
C. /var/lib/kubelet
D. /opt/cni/bin

👉 **ポイント**：

* `/etc/cni/net.d` に設定、`/opt/cni/bin` にバイナリ

---

### Q14

Pod 間通信ができない場合、**最初に疑うべきコンポーネント** はどれか

A. kube-proxy
B. CoreDNS
C. CNI Plugin
D. kube-apiserver

👉 **ポイント**：

* Pod 間の直接通信は CNI が担当、Service 経由は kube-proxy

---

## ⑧ RBAC（クラスタレベル）

### Q15

ClusterRole と Role の **違い** として正しいものはどれか

A. ClusterRole は namespace を指定できない
B. Role は cluster-scoped リソースにアクセスできる
C. ClusterRole は全 namespace に適用可能
D. Role は ClusterRoleBinding で使用できる

👉 **ポイント**：

* ClusterRole + ClusterRoleBinding = クラスタ全体
* ClusterRole + RoleBinding = 特定 namespace

---

### Q16

ServiceAccount に ClusterRole を紐付けるために **使用するリソース** はどれか

A. Role
B. RoleBinding
C. ClusterRoleBinding
D. ServiceAccountBinding

👉 **ポイント**：

* クラスタ全体の権限は ClusterRoleBinding が必要

---

## ⑨ ノードメンテナンス

### Q17

`kubectl cordon` を実行した後の Node の状態はどれか

A. NotReady
B. SchedulingDisabled
C. Unschedulable
D. Maintenance

👉 **ポイント**：

* cordon = SchedulingDisabled、既存 Pod は影響なし

---

### Q18

`kubectl drain` で **--ignore-daemonsets が必要な理由** はどれか

A. DaemonSet Pod は他の Node に移動できないため
B. DaemonSet Pod は自動的に削除されるため
C. DaemonSet Pod は特権モードで動作するため
D. DaemonSet Pod は PVC を使用しているため

👉 **ポイント**：

* DaemonSet は Node ごとに1つ、evict しても意味がない

---

## ⑩ ストレージクラス・動的プロビジョニング

### Q19

StorageClass の `reclaimPolicy: Delete` の意味として正しいものはどれか

A. PVC 削除時に PV も削除される
B. Pod 削除時に PVC も削除される
C. PV 削除時にデータが保持される
D. PVC 作成時に既存 PV が削除される

👉 **ポイント**：

* Delete = PVC削除で PV とストレージも削除
* Retain = PV は残る（手動削除が必要）

---

### Q20

PVC が Pending のまま Bound にならない原因として **最も多いもの** はどれか

A. StorageClass が存在しない
B. Pod が PVC を参照していない
C. Node が NotReady
D. kube-scheduler が停止している

👉 **ポイント**：

* 動的プロビジョニングには StorageClass が必須

---

## ⑪ kubeconfig / クラスタ接続

### Q21

複数クラスタを管理する環境で、**特定の kubeconfig を使用するコマンド** として正しいものはどれか

A. kubectl config use-context
B. export KUBECONFIG=/path/to/config
C. kubectl set-context
D. kubectl config view

👉 **ポイント**：

* `export KUBECONFIG=...` で環境変数を設定、または `--kubeconfig` フラグで指定
* `use-context` は同一ファイル内のコンテキスト切り替え

---

### Q22

control-plane 障害時に kubectl が動作しない場合、**最初に確認すべきこと** はどれか

A. kubelet の状態
B. KUBECONFIG の設定
C. kube-proxy の状態
D. CNI の設定

👉 **ポイント**：

* API に接続できない場合は kubeconfig の設定ミスが多い
* `export KUBECONFIG=/etc/kubernetes/admin.conf` で明示的に指定

---

## ⑫ Node ラベル / スケジューリング

### Q23

Node にラベルを追加するコマンドとして **正しいもの** はどれか

A. kubectl annotate node <node> key=value
B. kubectl label node <node> key=value
C. kubectl taint node <node> key=value
D. kubectl patch node <node> -p '{"labels":{"key":"value"}}'

👉 **ポイント**：

* `label` = スケジューリング（nodeSelector）で使用
* `annotate` = メタデータ（ツール連携等）
* `taint` = Pod の排除制御

---

### Q24

`kubectl get nodes --show-labels` で **確認できないもの** はどれか

A. kubernetes.io/hostname
B. node-role.kubernetes.io/control-plane
C. Node の Taints
D. topology.kubernetes.io/zone

👉 **ポイント**：

* `--show-labels` はラベルのみ表示、Taints は `describe node` で確認

---

## ⑬ コントロールプレーン確認

### Q25

kube-system namespace の Pod を確認するコマンドとして **最も適切なもの** はどれか

A. kubectl get pods
B. kubectl get pods -n kube-system
C. kubectl get pods --all-namespaces | grep kube
D. kubectl describe namespace kube-system

👉 **ポイント**：

* control-plane コンポーネントは `kube-system` に配置
* 障害調査の基本中の基本

---

### Q26

`kubectl get componentstatuses` で **確認できるもの** はどれか

A. kubelet の状態
B. scheduler, controller-manager, etcd の状態
C. kube-proxy の状態
D. CoreDNS の状態

👉 **ポイント**：

* componentstatuses（cs）で control-plane の死活確認
* ただし非推奨化が進んでいるため `get pods -n kube-system` も併用

---

## 使い方

* **各問題で「なぜその選択肢が正解/不正解か」を説明できるか確認**
* 迷った問題は実機で `kubectl` / `kubeadm` / `etcdctl` を実行して確認
* 試験では **トラブルシューティング** と **クラスタ管理** が大きな配点

---

## CKA 頻出コマンド一覧

### 🥇 Sランク（反射で打つ）

```bash
# kubeadm アップグレード
kubeadm upgrade plan
kubeadm upgrade apply v1.xx.x

# etcd バックアップ
ETCDCTL_API=3 etcdctl snapshot save /backup/etcd-snapshot.db \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key

# etcd リストア
ETCDCTL_API=3 etcdctl snapshot restore /backup/etcd-snapshot.db \
  --data-dir=/var/lib/etcd-restore

# Node メンテナンス
kubectl cordon <node>
kubectl drain <node> --ignore-daemonsets --delete-emptydir-data
kubectl uncordon <node>

# Static Pod 確認
ls /etc/kubernetes/manifests/

# kubeconfig 切り替え（control-plane障害時に必須）
export KUBECONFIG=/etc/kubernetes/admin.conf
```

### 🥈 Aランク（迷わず思い出す）

```bash
# 証明書確認
kubeadm certs check-expiration

# kube-system コンポーネント確認
kubectl get pods -n kube-system
kubectl describe pod <pod> -n kube-system

# Node ラベル確認・操作
kubectl get nodes --show-labels
kubectl label node <node> key=value

# kubelet トラブルシューティング
systemctl status kubelet
systemctl restart kubelet
journalctl -u kubelet -f
```

### 🥉 Bランク（知っていればOK）

```bash
# コンポーネント状態確認（非推奨化進行中）
kubectl get componentstatuses
kubectl get cs

# クラスタ情報
kubectl cluster-info

# kubelet 設定パス確認
ps aux | grep kubelet
```
