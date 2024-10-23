#!/bin/bash

# Verifică dacă ai kubectl și helm instalat
if ! command -v kubectl &> /dev/null || ! command -v helm &> /dev/null
then
    echo "kubectl și/sau helm nu sunt instalate. Asigură-te că ai acces la ele."
    exit 1
fi

# Setează variabile pentru namespace-uri și certificare SSL
CERT_ISSUER_NAME="letsencrypt"  # Dacă issuer-ul a rămas același
EMAIL="admin@elgg.ro"
CERT_NAMESPACE="cert-manager"
REPO_URL="https://github.com/prdmarian/k8s-objects.git"
CLONE_DIR="./k8s-objects"

# 1. Crează namespace-urile necesare
echo "Creare namespace-uri..."
sudo kubectl create namespace argocd
sudo kubectl create namespace monitoring
sudo kubectl create namespace cert-manager
sudo kubectl create namespace tools
sudo kubectl create namespace web-apps
sudo kubectl create namespace ingress-proxy-internal
sudo kubectl create namespace ingress-proxy-external

# 2. Adăugare repository-uri Helm
echo "Adăugare Helm repositories pentru aplicații..."
sudo helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
sudo helm repo add grafana https://grafana.github.io/helm-charts
sudo helm repo add jetstack https://charts.jetstack.io
sudo helm repo add bitnami https://charts.bitnami.com/bitnami
sudo helm repo add argo https://argoproj.github.io/argo-helm
sudo helm repo update

# 3. Clonare repository-ul k8s-objects pentru aplicațiile ArgoCD
if [ -d "$CLONE_DIR" ]; then
  echo "Directorul k8s-objects există deja. Ștergere și re-clonare..."
  rm -rf "$CLONE_DIR"
fi
echo "Clonare repository $REPO_URL ..."
git clone $REPO_URL $CLONE_DIR

# 4. Sincronizare aplicații cu ArgoCD (Cert-Manager, Ingress NGINX etc.)
echo "Sincronizare aplicații cu ArgoCD..."
sudo kubectl apply -f $CLONE_DIR/applications/cert-manager.yaml
sudo kubectl apply -f $CLONE_DIR/applications/prometheus.yaml
sudo kubectl apply -f $CLONE_DIR/applications/custom-exporter.yaml
sudo kubectl apply -f $CLONE_DIR/applications/grafana.yaml
sudo kubectl apply -f $CLONE_DIR/applications/ldap.yaml
sudo kubectl apply -f $CLONE_DIR/applications/git-cache.yaml
sudo kubectl apply -f $CLONE_DIR/applications/helm-cache.yaml
sudo kubectl apply -f $CLONE_DIR/applications/web-apps.yaml
sudo kubectl apply -f $CLONE_DIR/applications/ingress-proxy-internal.yaml
sudo kubectl apply -f $CLONE_DIR/applications/ingress-proxy-external.yaml

# 5. Verifică statusul deployment-urilor
echo "Verificare status deployment-uri..."
sudo kubectl get pods -n argocd
sudo kubectl get pods -n monitoring
sudo kubectl get pods -n tools
sudo kubectl get pods -n cert-manager
sudo kubectl get pods -n web-apps
sudo kubectl get pods -n ingress-proxy-internal
sudo kubectl get pods -n ingress-proxy-external

# 6. Finisare
echo "Implementarea aplicațiilor și configurarea sunt complete!"
