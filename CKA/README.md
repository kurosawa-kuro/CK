# CKA 試験対策リポジトリ

WSL + kind 環境で CKA (Certified Kubernetes Administrator) 試験対策を行うためのハンズオン教材です。

---

## クイックスタート

### 1. 環境セットアップ

```bash
# kind クラスタ作成
kind create cluster --name cka

# 確認
kubectl get nodes

# 推奨エイリアス設定
alias k=kubectl
export do="--dry-run=client -o yaml"
```

詳細は [setup.md](setup.md) を参照してください。

### 2. 最初の演習

```bash
# 実技問題の準備ファイルを適用
kubectl apply -f test/resources/cka/q1-node-maintenance.yaml

# 問題を開く
# test/CKA_実技問題_kind対応.md の問題1を参照
```

---

## リポジトリ構造

```
CKA/
├── README.md                 # このファイル
├── setup.md                  # 環境セットアップ手順
├── CLAUDE.md                 # Claude Code用（無視してOK）
│
├── docker-labs/              # Docker模擬環境（kind制限の補完）
│   ├── etcd-lab/             # etcdバックアップ・リストア演習
│   └── upgrade-lab/          # クラスタアップグレード学習
│
└── test/                     # 問題・学習資料
    ├── CKA_実技問題_kind対応.md      # ★メイン: 実技10問 + 詳細解答
    ├── learning-path.md              # 学習パスガイド
    ├── CKA_選択式クイズ_基礎.md      # 選択式クイズ
    ├── CKA_選択式クイズ_頻出.md      # 選択式クイズ（頻出）
    │
    ├── CKA特化知識/                  # 知識ドキュメント（8テーマ）
    │   ├── 01_クラスタアーキテクチャ.md
    │   ├── 02_etcdバックアップ・リストア.md
    │   ├── 03_クラスタアップグレード.md
    │   ├── 04_ノード管理.md
    │   ├── 05_RBAC.md
    │   ├── 06_トラブルシューティング.md
    │   ├── 07_証明書とkubeconfig.md
    │   ├── 08_JSONPathとカスタム出力.md
    │   └── CKA_実技問題.md           # テーマ別追加問題
    │
    └── resources/cka/                # 実技問題用YAMLファイル
        └── q1〜q10-*.yaml
```

---

## 学習の進め方

### Level 1: 入門（基礎固め）

各テーマの基本コマンドを習得します。

| 順番 | テーマ | ドキュメント |
|-----|-------|------------|
| 1 | クラスタアーキテクチャ | [01_クラスタアーキテクチャ.md](test/CKA特化知識/01_クラスタアーキテクチャ.md) |
| 2 | ノード管理基礎 | [04_ノード管理.md](test/CKA特化知識/04_ノード管理.md) |
| 3 | RBAC基礎 | [05_RBAC.md](test/CKA特化知識/05_RBAC.md) |
| 4 | JSONPath | [08_JSONPathとカスタム出力.md](test/CKA特化知識/08_JSONPathとカスタム出力.md) |

各ドキュメント末尾の「ミニ演習」を実施してください。

### Level 2: 中級（複合問題）

実技問題を解答例を参考にしながら実行します。

| 順番 | テーマ | 問題 |
|-----|-------|-----|
| 1 | ノードメンテナンス | [実技問題 問題1](test/CKA_実技問題_kind対応.md) |
| 2 | NodeSelector/Labels | [実技問題 問題9](test/CKA_実技問題_kind対応.md) |
| 3 | Taint/Toleration | [実技問題 問題3](test/CKA_実技問題_kind対応.md) |
| 4 | DaemonSet | [実技問題 問題4](test/CKA_実技問題_kind対応.md) |
| 5 | RBAC | [実技問題 問題2](test/CKA_実技問題_kind対応.md) |
| 6 | PV/PVC | [実技問題 問題5](test/CKA_実技問題_kind対応.md) |
| 7 | ResourceQuota | [実技問題 問題6](test/CKA_実技問題_kind対応.md) |

**追加学習（Docker模擬）:**
- [etcd-lab](docker-labs/etcd-lab/) - etcdバックアップ・リストア
- [upgrade-lab](docker-labs/upgrade-lab/) - クラスタアップグレード

### Level 3: 本番レベル（時間制限付き）

解答を見ずに問題を解きます。

| テーマ | 問題 | 目標時間 |
|-------|-----|---------|
| Service接続 | [実技問題 問題7](test/CKA_実技問題_kind対応.md) | 10分 |
| DNS | [実技問題 問題8](test/CKA_実技問題_kind対応.md) | 15分 |
| Events分析 | [実技問題 問題10](test/CKA_実技問題_kind対応.md) | 15分 |

詳細な学習パスは [learning-path.md](test/learning-path.md) を参照してください。

---

## コンテンツ説明

### 実技問題（10問）

[test/CKA_実技問題_kind対応.md](test/CKA_実技問題_kind対応.md)

| # | テーマ | 難易度 |
|---|-------|-------|
| 1 | ノードメンテナンス（drain/cordon） | ★★☆ |
| 2 | RBAC（ClusterRole/ClusterRoleBinding） | ★★☆ |
| 3 | Taint/Toleration | ★★☆ |
| 4 | DaemonSet | ★★☆ |
| 5 | PV/PVC | ★★☆ |
| 6 | ResourceQuota | ★★☆ |
| 7 | Service Selector修正 | ★★★ |
| 8 | DNS トラブルシューティング | ★★★ |
| 9 | NodeSelector | ★☆☆ |
| 10 | Events分析 | ★★★ |

各問題には以下が含まれます：
- 問題文
- 準備用YAMLファイル
- 詳細な解答例（コマンド + 出力例 + 解説）
- 確認方法

### 知識ドキュメント（8テーマ）

[test/CKA特化知識/](test/CKA特化知識/)

CKA試験の主要テーマを体系的に解説。各ドキュメントには：
- 概念説明
- コマンドリファレンス
- YAMLテンプレート
- ミニ演習（kind対応）

### Docker模擬環境

[docker-labs/](docker-labs/)

kindでは再現できない操作をDockerコンテナで模擬：
- **etcd-lab**: etcdctlによるバックアップ・リストア
- **upgrade-lab**: kubeadmアップグレード手順の学習

---

## 試験当日チェックリスト

```bash
# 開始直後に設定
alias k=kubectl
export do="--dry-run=client -o yaml"
source <(kubectl completion bash)

# vim設定
cat <<EOF > ~/.vimrc
set tabstop=2
set shiftwidth=2
set expandtab
EOF

# コンテキスト確認（各問題の最初に必ず実行）
kubectl config current-context
```

---

## よくある失敗と対策

| 失敗 | 対策 |
|-----|-----|
| 時間切れ | 難しい問題は後回し、簡単な問題から |
| コンテキスト間違い | 各問題で `kubectl config use-context` |
| Namespace忘れ | `-n <namespace>` を毎回確認 |
| YAMLインデント | `kubectl create --dry-run=client -o yaml` でベース作成 |

---

## 関連リンク

- [CKA試験公式ページ](https://training.linuxfoundation.org/certification/certified-kubernetes-administrator-cka/)
- [Kubernetes公式ドキュメント](https://kubernetes.io/docs/)
- [kind公式](https://kind.sigs.k8s.io/)
