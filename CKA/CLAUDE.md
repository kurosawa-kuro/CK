# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Purpose

This is a CKA (Certified Kubernetes Administrator) exam preparation repository. It contains practice questions, setup scripts, and sample Kubernetes manifests for exam study.

## Environment Setup

```bash
# Create kind cluster for CKA practice
kind delete cluster --name cka
kind create cluster --name cka
sleep 30
kubectl get nodes

# Recommended kubectl aliases
alias k=kubectl
export do="--dry-run=client -o yaml"
```

## Vim Configuration (for exam environment)

```bash
cat <<EOF > ~/.vimrc
set tabstop=2
set shiftwidth=2
set expandtab
set number
syntax on
EOF
```

## Repository Structure

- `setup.md` - Complete environment setup instructions (kind cluster, aliases, vim config)
- `deploy.yaml` - Sample nginx Deployment manifest
- `test/` - Practice exam questions
  - Contains CKA-specific questions (cluster management, control plane, networking, storage)
  - Contains CKAD practice problems from Udemy course

## Key Commands for Practice

```bash
# Common kubectl operations with dry-run
k create deploy nginx --image=nginx $do > deploy.yaml

# Cluster inspection
k get pods -A
k get nodes -o wide
k describe node <node-name>
```

## Practice Question Format

Questions in `test/` follow a consistent pattern:
1. Environment preparation (kubectl apply from remote URLs)
2. Problem description
3. Solution space (marked with dots)

Many questions reference resources from: `https://raw.githubusercontent.com/nz-cloud-udemy/ckad-questions/main/practice-questions/`
