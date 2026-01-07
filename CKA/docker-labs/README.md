# Docker Labs

kind環境では再現できないCKA試験の操作をDockerコンテナで模擬するための環境です。

---

## 概要

| Lab | 内容 | 試験での配点目安 |
|-----|------|----------------|
| [etcd-lab](etcd-lab/) | etcdバックアップ・リストア | 7-8% |
| [upgrade-lab](upgrade-lab/) | kubeadmクラスタアップグレード | 7-8% |

---

## 前提条件

- Docker と Docker Compose がインストール済み
- WSL2環境推奨

```bash
# 確認
docker --version
docker compose version
```

---

## etcd-lab

etcdctlを使ったバックアップ・リストア操作を練習します。

### 起動

```bash
cd etcd-lab
./setup.sh
# または
docker compose up -d
```

### 演習内容

1. etcdの状態確認
2. スナップショット作成（バックアップ）
3. スナップショットからリストア
4. 証明書オプションの理解

### 詳細

[etcd-lab/README.md](etcd-lab/README.md) を参照

---

## upgrade-lab

kubeadmによるクラスタアップグレード手順を学習します。

### 起動

```bash
cd upgrade-lab
./setup.sh
# または
docker compose up -d
```

### 演習内容

1. 現在のバージョン確認
2. kubeadm upgrade plan
3. コントロールプレーンのアップグレード
4. ノードのアップグレード

### 詳細

[upgrade-lab/README.md](upgrade-lab/README.md) を参照

---

## クリーンアップ

```bash
# etcd-lab
cd etcd-lab && docker compose down -v

# upgrade-lab
cd upgrade-lab && docker compose down -v
```

---

## 注意事項

- これらのLabは**コマンド構文の習得**が目的です
- 実際のkubeadmクラスタとは挙動が異なる部分があります
- 本番CKA試験では、実際のkubeadmクラスタで操作を行います
