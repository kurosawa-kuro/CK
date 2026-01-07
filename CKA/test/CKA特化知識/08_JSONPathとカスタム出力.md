# CKA特化: JSONPath とカスタム出力

## 概要

CKA試験では特定の情報を抽出してファイルに保存する問題が頻出。
JSONPath と custom-columns を使いこなすことが重要。

---

## 出力形式の種類

```bash
# 出力形式オプション
-o yaml          # YAML形式
-o json          # JSON形式
-o wide          # 追加情報付き
-o name          # リソース名のみ
-o jsonpath      # JSONPathで抽出
-o custom-columns # カスタムカラム
```

---

## 1. JSONPath 基本構文

### 基本形式

```bash
# 基本形式
kubectl get <resource> -o jsonpath='{<expression>}'

# 複数フィールド
kubectl get <resource> -o jsonpath='{.field1}{.field2}'

# 改行を入れる
kubectl get <resource> -o jsonpath='{.field1}{"\n"}'
```

### よく使う演算子

| 演算子 | 説明 | 例 |
|-------|------|-----|
| `.` | 子要素 | `.metadata.name` |
| `[]` | 配列インデックス | `.items[0]` |
| `[*]` | 全要素 | `.items[*]` |
| `..` | 再帰的検索 | `..name` |
| `?()` | フィルタ | `[?(@.type=="Ready")]` |

---

## 2. 実践例（Pod）

### Pod名の取得

```bash
# 単一Pod
kubectl get pod nginx -o jsonpath='{.metadata.name}'

# 全Podの名前
kubectl get pods -o jsonpath='{.items[*].metadata.name}'

# 改行付き
kubectl get pods -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}'
```

### Podのイメージ取得

```bash
# 単一Pod
kubectl get pod nginx -o jsonpath='{.spec.containers[0].image}'

# 全Podのイメージ
kubectl get pods -o jsonpath='{.items[*].spec.containers[*].image}'
```

### Pod IP の取得

```bash
kubectl get pod nginx -o jsonpath='{.status.podIP}'
```

---

## 3. 実践例（Node）

### Node名の取得

```bash
kubectl get nodes -o jsonpath='{.items[*].metadata.name}'
```

### Node の Internal IP

```bash
# Internal IP を取得
kubectl get nodes -o jsonpath='{.items[*].status.addresses[?(@.type=="InternalIP")].address}'
```

### Node の OS イメージ

```bash
kubectl get nodes -o jsonpath='{.items[*].status.nodeInfo.osImage}'
```

### Ready 状態のノード

```bash
kubectl get nodes -o jsonpath='{.items[*].status.conditions[?(@.type=="Ready")].status}'
```

---

## 4. range を使った繰り返し

### 基本構文

```bash
kubectl get pods -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.phase}{"\n"}{end}'
```

### Pod名とノード名

```bash
kubectl get pods -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.nodeName}{"\n"}{end}'
```

### Service名とClusterIP

```bash
kubectl get svc -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.clusterIP}{"\n"}{end}'
```

---

## 5. custom-columns

### 基本構文

```bash
# 基本形式
kubectl get <resource> -o custom-columns=<HEADER>:<JSONPATH>

# 複数カラム
kubectl get <resource> -o custom-columns=NAME:.metadata.name,STATUS:.status.phase
```

### Pod の例

```bash
# 名前とステータス
kubectl get pods -o custom-columns=NAME:.metadata.name,STATUS:.status.phase

# 名前とイメージ
kubectl get pods -o custom-columns=NAME:.metadata.name,IMAGE:.spec.containers[0].image

# 名前とノード
kubectl get pods -o custom-columns=NAME:.metadata.name,NODE:.spec.nodeName
```

### Node の例

```bash
# 名前とOSイメージ
kubectl get nodes -o custom-columns=NAME:.metadata.name,OS:.status.nodeInfo.osImage

# 名前とkubeletバージョン
kubectl get nodes -o custom-columns=NAME:.metadata.name,VERSION:.status.nodeInfo.kubeletVersion
```

---

## 6. sort-by でソート

```bash
# 作成時刻でソート
kubectl get pods --sort-by=.metadata.creationTimestamp

# 名前でソート
kubectl get pods --sort-by=.metadata.name

# リソース使用量でソート（要metrics-server）
kubectl top pods --sort-by=cpu
kubectl top pods --sort-by=memory
```

---

## 7. ファイルへの出力

### 試験で頻出のパターン

```bash
# Pod名を一覧でファイルに保存
kubectl get pods -o jsonpath='{.items[*].metadata.name}' > /tmp/pods.txt

# 改行区切りで保存
kubectl get pods -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}' > /tmp/pods.txt

# Node の Internal IP をファイルに保存
kubectl get nodes -o jsonpath='{.items[*].status.addresses[?(@.type=="InternalIP")].address}' > /tmp/ips.txt
```

---

## 8. 試験頻出パターン

### パターン1: Pod の情報抽出

```bash
# 問題: Ready状態のPod名をファイルに保存

# 解答
kubectl get pods -o jsonpath='{range .items[?(@.status.phase=="Running")]}{.metadata.name}{"\n"}{end}' > /opt/pods.txt
```

### パターン2: Node のIP抽出

```bash
# 問題: 全NodeのInternalIPをファイルに保存

# 解答
kubectl get nodes -o jsonpath='{range .items[*]}{.status.addresses[?(@.type=="InternalIP")].address}{"\n"}{end}' > /opt/node-ips.txt
```

### パターン3: 特定ラベルのPod

```bash
# 問題: app=nginx のPod名を取得

# 解答
kubectl get pods -l app=nginx -o jsonpath='{.items[*].metadata.name}'
```

### パターン4: PV の容量確認

```bash
# 問題: PVの名前と容量を取得

# 解答
kubectl get pv -o custom-columns=NAME:.metadata.name,CAPACITY:.spec.capacity.storage
```

### パターン5: Context 情報

```bash
# 問題: 現在の context で使用しているユーザー名を取得

# 解答
kubectl config view -o jsonpath='{.contexts[?(@.name=="'$(kubectl config current-context)'")].context.user}'
```

---

## 9. デバッグテクニック

### JSON構造を確認

```bash
# まずJSON全体を見る
kubectl get pod nginx -o json

# jq で整形（インストールされている場合）
kubectl get pod nginx -o json | jq .

# 特定のパスを確認
kubectl get pod nginx -o json | jq '.status.conditions'
```

### JSONPathのテスト

```bash
# シンプルなパスから始める
kubectl get pod nginx -o jsonpath='{.metadata}'
kubectl get pod nginx -o jsonpath='{.metadata.name}'
kubectl get pod nginx -o jsonpath='{.spec.containers}'
kubectl get pod nginx -o jsonpath='{.spec.containers[0]}'
kubectl get pod nginx -o jsonpath='{.spec.containers[0].image}'
```

---

## 10. よくあるエラーと対処

### エラー1: パスが見つからない

```bash
# 間違い
kubectl get pod nginx -o jsonpath='{.container.image}'

# 正しい
kubectl get pod nginx -o jsonpath='{.spec.containers[0].image}'
```

### エラー2: 配列のインデックス忘れ

```bash
# 間違い（配列なのにインデックスがない）
kubectl get pods -o jsonpath='{.items.metadata.name}'

# 正しい
kubectl get pods -o jsonpath='{.items[*].metadata.name}'
```

### エラー3: クォートの問題

```bash
# シェルのクォート問題を避けるため、シングルクォートを使う
kubectl get pods -o jsonpath='{.items[*].metadata.name}'
```

---

## クイックリファレンス

```bash
# Pod名一覧
kubectl get pods -o jsonpath='{.items[*].metadata.name}'

# Pod名（改行付き）
kubectl get pods -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}'

# Node Internal IP
kubectl get nodes -o jsonpath='{.items[*].status.addresses[?(@.type=="InternalIP")].address}'

# カスタムカラム
kubectl get pods -o custom-columns=NAME:.metadata.name,STATUS:.status.phase

# ソート
kubectl get pods --sort-by=.metadata.creationTimestamp

# ファイル出力
kubectl get pods -o jsonpath='{...}' > /path/to/file
```

---

## 実際のリソースパス早見表

| 情報 | JSONPath |
|-----|----------|
| Pod名 | `.metadata.name` |
| Namespace | `.metadata.namespace` |
| ラベル | `.metadata.labels` |
| Pod IP | `.status.podIP` |
| ノード名 | `.spec.nodeName` |
| イメージ | `.spec.containers[0].image` |
| フェーズ | `.status.phase` |
| Node Internal IP | `.status.addresses[?(@.type=="InternalIP")].address` |
| Node OS | `.status.nodeInfo.osImage` |
| kubelet Version | `.status.nodeInfo.kubeletVersion` |

---

## ミニ演習（kind対応）

### 演習1: 基本的なJSONPath

```bash
# テスト用Podを作成
kubectl run web1 --image=nginx --labels="tier=frontend"
kubectl run web2 --image=nginx --labels="tier=frontend"
kubectl run api1 --image=nginx --labels="tier=backend"

# 全Pod名を取得
kubectl get pods -o jsonpath='{.items[*].metadata.name}'

# 改行付き
kubectl get pods -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}'

# 特定ラベルのPod
kubectl get pods -l tier=frontend -o jsonpath='{.items[*].metadata.name}'
```

### 演習2: ノード情報の抽出

```bash
# ノード名一覧
kubectl get nodes -o jsonpath='{.items[*].metadata.name}'

# Internal IP
kubectl get nodes -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.addresses[?(@.type=="InternalIP")].address}{"\n"}{end}'

# kubeletバージョン
kubectl get nodes -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.nodeInfo.kubeletVersion}{"\n"}{end}'
```

### 演習3: カスタムカラム

```bash
# Pod情報をカスタム表示
kubectl get pods -o custom-columns=NAME:.metadata.name,STATUS:.status.phase,NODE:.spec.nodeName

# ノード情報をカスタム表示
kubectl get nodes -o custom-columns=NAME:.metadata.name,VERSION:.status.nodeInfo.kubeletVersion,OS:.status.nodeInfo.osImage
```

### 演習4: ファイル出力（試験頻出）

```bash
# JSONPathの結果をファイルに保存
kubectl get pods -o jsonpath='{.items[*].metadata.name}' > /tmp/pod-names.txt

# 確認
cat /tmp/pod-names.txt

# 複数行形式でファイル保存
kubectl get pods -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}' > /tmp/pod-list.txt

cat /tmp/pod-list.txt
```

### 演習5: ソートと組み合わせ

```bash
# 作成日時でソート
kubectl get pods --sort-by=.metadata.creationTimestamp

# ソート + JSONPath
kubectl get pods --sort-by=.metadata.creationTimestamp -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}'
```

### クリーンアップ

```bash
kubectl delete pod web1 web2 api1
rm /tmp/pod-names.txt /tmp/pod-list.txt
```
