#!/bin/bash
# Script de preparación para nodos Kubernetes
# Basado en: https://github.com/jlbisconti/k8s-vanilla/blob/main/deployments_documentacion/infra_k8s/cluster%20k8s/k8s_ha_instalacion.md

set -e

# Variables
MODPROBE_FILE=/etc/modules-load.d/containerd.conf
SYSCTL_FILE=/etc/sysctl.d/99-kubernetes-cri.conf

### 1. Desactivar swap
echo ">>> Desactivando swap..."
swapoff -a
sed -i '/ swap / s/^/#/' /etc/fstab

### 2. Requisitos del sistema
echo ">>> Configurando modulos del kernel..."
cat <<EOF > $MODPROBE_FILE
overlay
br_netfilter
EOF

modprobe overlay
modprobe br_netfilter

echo ">>> Configurando sysctl..."
cat <<EOF > $SYSCTL_FILE
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sysctl --system

### 3. Instalación de containerd
echo ">>> Instalando containerd..."
apt update && apt install -y containerd
mkdir -p /etc/containerd
containerd config default > /etc/containerd/config.toml
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
systemctl restart containerd
systemctl enable containerd

### 4. Instalar kubeadm, kubelet y kubectl
echo ">>> Instalando kubeadm, kubelet y kubectl..."
apt install -y apt-transport-https ca-certificates curl gpg
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /" \
  > /etc/apt/sources.list.d/kubernetes.list

apt update
apt install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl

systemctl enable kubelet

echo ">>> Setup completado. El nodo está listo para unirse al cluster Kubernetes."
