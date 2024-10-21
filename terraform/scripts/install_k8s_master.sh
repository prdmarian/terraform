#!/bin/bash

MASTER_NODE_IP="192.168.56.11"

# Ensure the system is updated
sudo apt-get update
sudo apt-get install -y curl gpg apt-transport-https ca-certificates git
sudo apt-get install -y socat


sudo sysctl --system
sudo apt update
sudo apt upgrade -y
sudo swapoff -a
# Comment out the swap entry in /etc/fstab
sudo sed -i.bak '/swap/ s/^\(.*\)$/#\1/g' /etc/fstab
echo "Swap has been disabled, and the /etc/fstab entry has been commented out."

# Load necessary kernel modules for Kubernetes networking
sudo tee /etc/modules-load.d/containerd.conf <<EOF
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

# Kubernetes network settings
sudo tee /etc/sysctl.d/kubernetes.conf <<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF

# Apply changes without reboot
sudo sysctl --system

# Setup Kubernetes repository
sudo mkdir -p -m 755 /etc/apt/keyrings
curl -fsSL "https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key" | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo chmod 644 /etc/apt/sources.list.d/kubernetes.list

# Install Kubernetes tools
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

# Setup Docker repository and install Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list

sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Configure containerd
sudo tee /etc/containerd/config.toml <<EOF
[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc]
[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]
SystemdCgroup = true
EOF

sudo sed -i 's/^disabled_plugins \=/\#disabled_plugins \=/g' /etc/containerd/config.toml
sudo systemctl restart containerd

# Initialize Kubernetes control plane
sudo kubeadm init --apiserver-advertise-address=$MASTER_NODE_IP --pod-network-cidr=192.168.0.0/16

# Configure kubectl for the current user
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Set KUBECONFIG environment variable
export KUBECONFIG=/etc/kubernetes/admin.conf

# Apply Calico CNI plugin for networking
sudo kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.25.0/manifests/calico.yaml

# Generate the join command for worker nodes
sudo kubeadm token create --print-join-command > /vagrant/join_command.sh

# Troubleshooting steps for kubelet and control plane issues

# Check kubelet status
sudo systemctl status kubelet

# Check kubelet logs for more information
sudo journalctl -xeu kubelet

# In case of control plane issues, list running Kubernetes containers
sudo crictl --runtime-endpoint unix:///var/run/containerd/containerd.sock ps -a | grep kube | grep -v pause

# To view logs of a failing container, replace CONTAINERID with the ID from the previous command
# sudo crictl --runtime-endpoint unix:///var/run/containerd/containerd.sock logs CONTAINERID

# set up autocomplete in bash into the current shell, bash-completion package should be installed first.
source <(kubectl completion bash)
# add autocomplete permanently to your bash shell.
echo "source <(kubectl completion bash)" >> ~/.bashrc 

alias k=kubectl
complete -o default -F __start_kubectl k

sudo kubectl apply -f /etc/kubernetes/provisioner/provisioner-rbac.yaml
sudo kubectl apply -f /etc/kubernetes/provisioner/provisioner.yaml

curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update
sudo apt-get install helm -y
sudo helm repo add bitnami https://charts.bitnami.com/bitnami
sudo helm repo add argo https://argoproj.github.io/argo-helm