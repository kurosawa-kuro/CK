# =========================================
# 1. kind クラスタの再作成（CKA用）
# =========================================
kind delete cluster --name cka
kind create cluster --name cka --config kind-config.yaml
sleep 30
kubectl get nodes


# =========================================
# 2. kubectl 操作効率化（alias / dry-run）
# =========================================
# alias（必須）
alias k=kubectl
export do="--dry-run=client -o yaml"


# =========================================
# 3. vim 設定（CKA試験向け）
# =========================================
# vim（試験用）
cat <<EOF > ~/.vimrc
set tabstop=2
set shiftwidth=2
set expandtab
set number
syntax on
EOF


# =========================================
# 4. クラスタ状態確認（初期）
# =========================================
k get pods -A
k get nodes -o wide
k describe node cka-control-plane


# =========================================
# 5. Deployment 作成（dry-run → YAML編集）
# =========================================
k create deploy nginx --image=nginx $do > deploy.yaml
vim deploy.yaml
k apply -f deploy.yaml
