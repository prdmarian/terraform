#!/bin/bash

# Verifică dacă ai kubectl și helm instalat
if ! command -v kubectl &> /dev/null || ! command -v helm &> /dev/null
then
    echo "kubectl și/sau helm nu sunt instalate. Asigură-te că ai acces la ele."
    exit 1
fi

# Setează variabile pentru namespace-uri și certificare SSL
CERT_ISSUER_NAME="letsencrypt-prod"
EMAIL="admin@elgg.ro"
CERT_NAMESPACE="letsencrypt"
REPO_URL="https://github.com/prdmarian/k8s-objects.git"
CLONE_DIR="./k8s-objects"

# 1. Crează namespace-urile necesare
echo "Creare namespace-uri..."
kubectl create namespace argocd
kubectl create namespace monitoring
kubectl create namespace letsencrypt
kubectl create namespace tools
kubectl create namespace web-apps
kubectl create namespace ingress-proxy-internal
kubectl create namespace ingress-proxy-external

# 2. Adăugare repository-uri Helm
echo "Adăugare Helm repositories pentru aplicații..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo add jetstack https://charts.jetstack.io
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

# 3. Clonare repository-ul k8s-objects pentru aplicațiile ArgoCD
if [ -d "$CLONE_DIR" ]; then
  echo "Directorul k8s-objects există deja. Ștergere și re-clonare..."
  rm -rf "$CLONE_DIR"
fi
echo "Clonare repository $REPO_URL ..."
git clone $REPO_URL $CLONE_DIR

# 4. Sincronizare aplicații cu ArgoCD (Cert-Manager, Ingress NGINX etc.)
echo "Sincronizare aplicații cu ArgoCD..."
kubectl apply -f $CLONE_DIR/applications/letsencrypt.yaml
kubectl apply -f $CLONE_DIR/applications/prometheus.yaml
kubectl apply -f $CLONE_DIR/applications/grafana.yaml
kubectl apply -f $CLONE_DIR/applications/ldap.yaml
kubectl apply -f $CLONE_DIR/applications/git-cache.yaml
kubectl apply -f $CLONE_DIR/applications/helm-cache.yaml
kubectl apply -f $CLONE_DIR/applications/web-apps.yaml
kubectl apply -f $CLONE_DIR/applications/ingress-proxy-internal.yaml
kubectl apply -f $CLONE_DIR/applications/ingress-proxy-external.yaml

# 5. Verifică statusul deployment-urilor
echo "Verificare status deployment-uri..."
kubectl get pods -n argocd
kubectl get pods -n monitoring
kubectl get pods -n tools
kubectl get pods -n letsencrypt
kubectl get pods -n web-apps
kubectl get pods -n ingress-proxy-internal
kubectl get pods -n ingress-proxy-external

# 6. Finisare
echo "Implementarea aplicațiilor și configurarea sunt complete!"
