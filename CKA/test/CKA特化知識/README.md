# CKA特化知識ドキュメント

CKA試験に特化した基礎知識集。CKADと重複するテーマは省略。

---

## ドキュメント一覧

| No | ファイル | 内容 | 重要度 |
|----|---------|------|-------|
| 01 | [クラスタアーキテクチャ](01_クラスタアーキテクチャ.md) | コントロールプレーン、ノードコンポーネント、障害時の影響 | ★★★ |
| 02 | [etcdバックアップ・リストア](02_etcdバックアップ・リストア.md) | snapshot save/restore、証明書パス | ★★★ |
| 03 | [クラスタアップグレード](03_クラスタアップグレード.md) | kubeadm upgrade、kubelet更新 | ★★★ |
| 04 | [ノード管理](04_ノード管理.md) | drain/cordon、Taint/Toleration、NodeAffinity | ★★★ |
| 05 | [RBAC](05_RBAC.md) | Role、ClusterRole、ServiceAccount | ★★☆ |
| 06 | [トラブルシューティング](06_トラブルシューティング.md) | Pod/Node/Service/DNS/コントロールプレーン | ★★★ |
| 07 | [証明書とkubeconfig](07_証明書とkubeconfig.md) | 証明書更新、CSR、kubeconfig操作 | ★★☆ |
| 08 | [JSONPathとカスタム出力](08_JSONPathとカスタム出力.md) | jsonpath、custom-columns、ファイル出力 | ★★☆ |

---

## CKA vs CKAD の出題範囲比較

### CKA特有（このドキュメントでカバー）

```
- クラスタのインストール・設定（kubeadm）
- etcdのバックアップ・リストア
- クラスタのアップグレード
- ノードのメンテナンス（drain/cordon）
- 証明書管理
- コントロールプレーンのトラブルシューティング
- kubelet/kube-proxyのトラブルシューティング
```

### CKAD共通（このドキュメントでは省略）

```
- Pod/Deployment/Service の作成
- ConfigMap/Secret
- PVC（基本操作）
- Liveness/Readiness Probe
- Resources (requests/limits)
- マルチコンテナPod
```

---

## 試験対策の優先順位

### 最優先（30%以上）
1. **トラブルシューティング** - 試験の約30%
2. **クラスタアップグレード** - 必ず出る
3. **etcdバックアップ** - 必ず出る

### 高優先（20%程度）
4. **ノード管理** - drain/Taint
5. **RBAC** - ServiceAccountと権限

### 中優先（10%程度）
6. **クラスタアーキテクチャ** - 理解問題
7. **証明書/kubeconfig** - 設定問題
8. **JSONPath** - 情報抽出

---

## 試験当日チェックリスト

### 開始前
```
□ kubectl補完が有効 (source <(kubectl completion bash))
□ alias k=kubectl が設定済み
□ export do="--dry-run=client -o yaml"
□ vim設定 (tabstop=2, expandtab)
```

### 各問題で確認
```
□ 正しいコンテキストか (kubectl config current-context)
□ 正しいNamespaceか
□ 問題の要件を全て満たしたか
```

---

## クイックリファレンス

### etcdバックアップ
```bash
ETCDCTL_API=3 etcdctl snapshot save /backup/snap.db \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key
```

### クラスタアップグレード
```bash
# kubeadm
apt-mark unhold kubeadm && apt install -y kubeadm=1.30.0-00 && apt-mark hold kubeadm
kubeadm upgrade apply v1.30.0

# kubelet
kubectl drain <node> --ignore-daemonsets
apt-mark unhold kubelet kubectl && apt install -y kubelet=1.30.0-00 kubectl=1.30.0-00 && apt-mark hold kubelet kubectl
systemctl daemon-reload && systemctl restart kubelet
kubectl uncordon <node>
```

### ノード管理
```bash
kubectl drain <node> --ignore-daemonsets --force
kubectl cordon <node>
kubectl uncordon <node>
kubectl taint nodes <node> key=value:NoSchedule
kubectl taint nodes <node> key-
```

### RBAC
```bash
kubectl create role <name> --verb=get,list --resource=pods -n <ns>
kubectl create rolebinding <name> --role=<role> --serviceaccount=<ns>:<sa> -n <ns>
kubectl auth can-i get pods --as <user>
```

### トラブルシューティング
```bash
kubectl describe pod <pod>
kubectl logs <pod> --previous
systemctl status kubelet
journalctl -u kubelet
```
