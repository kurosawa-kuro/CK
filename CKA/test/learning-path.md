# CKA 学習パス

WSL + kind環境での段階的なCKA試験対策ガイドです。

---

## 学習フロー概要

```
Level 1 (入門)      → Level 2 (中級)        → Level 3 (本番レベル)
基礎コマンド習得       複合問題演習             時間制限付き演習
各テーマの理解        トラブルシューティング     模擬試験
```

---

## Level 1: 入門（各テーマの基礎）

### 目標
- 各テーマの基本コマンドを覚える
- 知識ドキュメントのミニ演習を完了する

### 学習順序

| 順番 | テーマ | ドキュメント | 所要時間目安 |
|-----|-------|------------|------------|
| 1 | クラスタアーキテクチャ | [01_クラスタアーキテクチャ.md](CKA特化知識/01_クラスタアーキテクチャ.md) | 30分 |
| 2 | ノード管理基礎 | [04_ノード管理.md](CKA特化知識/04_ノード管理.md) | 45分 |
| 3 | RBAC基礎 | [05_RBAC.md](CKA特化知識/05_RBAC.md) | 45分 |
| 4 | JSONPath | [08_JSONPathとカスタム出力.md](CKA特化知識/08_JSONPathとカスタム出力.md) | 30分 |

### チェックリスト

```
□ kubectl get/describe/logs を使いこなせる
□ cordon/drain/uncordon の違いを説明できる
□ Role/ClusterRole の違いを説明できる
□ JSONPath で情報を抽出できる
```

---

## Level 2: 中級（複合問題）

### 目標
- 実技問題を解答を見ながら実行できる
- 各操作の「なぜ」を理解する

### 学習順序

| 順番 | テーマ | 問題 | 所要時間目安 |
|-----|-------|-----|------------|
| 1 | ノードメンテナンス | [実技問題 問題1](CKA_実技問題_kind対応.md) | 20分 |
| 2 | NodeSelector/Labels | [実技問題 問題9](CKA_実技問題_kind対応.md) | 15分 |
| 3 | Taint/Toleration | [実技問題 問題3](CKA_実技問題_kind対応.md) | 20分 |
| 4 | DaemonSet | [実技問題 問題4](CKA_実技問題_kind対応.md) | 20分 |
| 5 | RBAC | [実技問題 問題2](CKA_実技問題_kind対応.md) | 25分 |
| 6 | PV/PVC | [実技問題 問題5](CKA_実技問題_kind対応.md) | 20分 |
| 7 | ResourceQuota | [実技問題 問題6](CKA_実技問題_kind対応.md) | 20分 |

### 追加学習

| テーマ | ドキュメント |
|-------|------------|
| etcdバックアップ | [02_etcdバックアップ・リストア.md](CKA特化知識/02_etcdバックアップ・リストア.md) + [etcd-lab](../docker-labs/etcd-lab/README.md) |
| クラスタアップグレード | [03_クラスタアップグレード.md](CKA特化知識/03_クラスタアップグレード.md) + [upgrade-lab](../docker-labs/upgrade-lab/README.md) |
| kubeconfig | [07_証明書とkubeconfig.md](CKA特化知識/07_証明書とkubeconfig.md) |

### チェックリスト

```
□ drain コマンドのオプションを暗記している
□ Taint/Toleration のYAMLを書ける
□ ClusterRole/ClusterRoleBinding を作成できる
□ PV/PVC のバインド条件を説明できる
□ etcd snapshot save/restore コマンドを暗記している
```

---

## Level 3: 本番レベル（トラブルシューティング + 時間制限）

### 目標
- 解答を見ずに問題を解ける
- 制限時間内に完了できる

### トラブルシューティング問題

| 順番 | テーマ | 問題 | 目標時間 |
|-----|-------|-----|---------|
| 1 | Service接続 | [実技問題 問題7](CKA_実技問題_kind対応.md) | 10分 |
| 2 | DNS | [実技問題 問題8](CKA_実技問題_kind対応.md) | 15分 |
| 3 | Events分析 | [実技問題 問題10](CKA_実技問題_kind対応.md) | 15分 |

### 追加トラブルシューティング

[06_トラブルシューティング.md](CKA特化知識/06_トラブルシューティング.md) のミニ演習全て

### 模擬試験モード

以下の手順で本番を想定した練習を行います：

```bash
# 1. kindクラスタを初期化
kind delete cluster --name cka
cat <<EOF > kind-config.yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
- role: worker
- role: worker
EOF
kind create cluster --name cka --config kind-config.yaml

# 2. タイマーをセット（2時間）

# 3. 全10問を順番に解く（解答を見ない）
# 各問題のリソースを apply してから解く

# 4. 採点
# 各問題の「確認方法」に従って正誤判定
```

### チェックリスト

```
□ 問題を見て10秒以内に解法が浮かぶ
□ kubectl コマンドをタイプミスなく打てる
□ YAML の インデントを間違えない
□ エラーメッセージから原因を特定できる
□ 10問を2時間以内に完了できる
```

---

## テーマ別リファレンス

### ノード管理

| 難易度 | 内容 | リソース |
|-------|------|---------|
| 入門 | cordon/uncordon | 知識ドキュメント ミニ演習1 |
| 中級 | drain + Taint | 実技問題 1, 3, 4 |
| 上級 | NodeAffinity | 知識ドキュメント Section 4 |

### RBAC

| 難易度 | 内容 | リソース |
|-------|------|---------|
| 入門 | Role/RoleBinding | 知識ドキュメント ミニ演習1-2 |
| 中級 | ClusterRole/ClusterRoleBinding | 実技問題 2 |
| 上級 | auth can-i | 知識ドキュメント ミニ演習2 |

### トラブルシューティング

| 難易度 | 内容 | リソース |
|-------|------|---------|
| 入門 | describe/logs | 知識ドキュメント ミニ演習1-4 |
| 中級 | Service/DNS | 実技問題 7, 8 |
| 上級 | Events分析 | 実技問題 10 |

### etcd/アップグレード

| 難易度 | 内容 | リソース |
|-------|------|---------|
| 入門 | コマンド暗記 | 知識ドキュメント |
| 中級 | Docker模擬 | docker-labs |
| 上級 | 手順暗記 | - |

---

## 推奨学習スケジュール

### 1週間集中コース

| 日 | 内容 |
|---|------|
| Day 1 | Level 1 全て |
| Day 2 | Level 2 (問題1-4) |
| Day 3 | Level 2 (問題5-7) + etcd-lab |
| Day 4 | Level 2 (問題8-10) + upgrade-lab |
| Day 5 | Level 3 トラブルシューティング |
| Day 6 | 模擬試験 (1回目) |
| Day 7 | 弱点補強 + 模擬試験 (2回目) |

### 2週間コース

| 週 | 内容 |
|---|------|
| Week 1 | Level 1 + Level 2 (各問題をじっくり) |
| Week 2 | Level 3 + 模擬試験3回 |

---

## 試験当日チェックリスト

```bash
# 開始直後に設定
alias k=kubectl
export do="--dry-run=client -o yaml"
source <(kubectl completion bash)

# vim設定（必要なら）
cat <<EOF > ~/.vimrc
set tabstop=2
set shiftwidth=2
set expandtab
EOF

# コンテキスト確認
kubectl config current-context
```

---

## よくある失敗と対策

| 失敗 | 対策 |
|-----|-----|
| 時間切れ | 難しい問題は後回し、簡単な問題から |
| コンテキスト間違い | 各問題で `kubectl config use-context` |
| Namespace忘れ | `-n <namespace>` を毎回確認 |
| YAML インデント | `kubectl create --dry-run=client -o yaml` でベース作成 |
| 証明書パス暗記漏れ | `/etc/kubernetes/pki/etcd/` を繰り返し書く |
