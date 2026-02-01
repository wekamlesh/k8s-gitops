#!/bin/bash
set -e

echo "🚀 Starting the K3s Fortress Build..."

# --- 1. System Hardening & Dependencies ---
echo "🛠️ Updating System..."
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl unzip git ufw

# --- 2. Firewall Configuration (Default Deny) ---
echo "🔒 Configuring Firewall..."
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp # SSH (Keep this open until we verify the tunnel)
sudo ufw --force enable

# --- 3. Install K3s (Optimized for 8GB RAM) ---
# We disable Traefik and ServiceLB because Cloudflare Tunnel is our gateway
echo "📦 Installing K3s..."
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server --disable traefik --disable servicelb --write-kubeconfig-mode 644 --node-name k8s-node" sh -

# Wait for K3s to initialize
echo "⏳ Waiting for K3s to wake up..."
sleep 10

# --- 4. Environment Tooling (Helm & K9s) ---
echo "🧰 Installing Helm..."
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

echo "🐶 Installing K9s..."
K9S_VERSION=$(curl -s https://api.github.com/repos/derailed/k9s/releases/latest | grep tag_name | cut -d '"' -f 4)
curl -L -s https://github.com/derailed/k9s/releases/download/${K9S_VERSION}/k9s_Linux_amd64.tar.gz | sudo tar -xz -C /usr/local/bin k9s
sudo chmod +x /usr/local/bin/k9s

# --- 5. Secure Kubeconfig & Aliases ---
echo "🔧 Configuring kubectl environment..."
mkdir -p ~/.kube
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown $(id -u):$(id -g) ~/.kube/config

# Add aliases to .bashrc if not already present
if ! grep -q "alias k='kubectl'" ~/.bashrc; then
    cat <<'EOT' >> ~/.bashrc

# Kubernetes aliases
export KUBECONFIG=~/.kube/config
alias k='kubectl'
alias ks='k9s'
alias kgp='kubectl get pods'
alias kgn='kubectl get nodes'
alias kga='kubectl get all'
alias kns='kubectl config set-context --current --namespace'
EOT
    echo "✅ Aliases added to .bashrc"
fi

# Source the new aliases
source ~/.bashrc

echo "----------------------------------------------------"
echo "✅ FOUNDATION LAID SUCCESSFULLY!"
echo "----------------------------------------------------"
echo ""
echo "Next steps:"
echo "1. Log out and log back in (or run: source ~/.bashrc)"
echo "2. Verify K3s: kubectl get nodes"
echo "3. Continue with Part 1, Step 6 (Cloudflare Tunnel)"
echo "----------------------------------------------------"
