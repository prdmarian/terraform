#!/bin/bash

# Install Helm if not already installed
if ! command -v helm &> /dev/null; then
  curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash
fi

# Add Prometheus community repository and update
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Install Prometheus and Grafana
helm install prometheus prometheus-community/kube-prometheus-stack --namespace monitoring --create-namespace

# Wait for Prometheus and Grafana to become ready
kubectl wait --for=condition=Ready pods --all -n monitoring --timeout=300s

# Expose Grafana through a NodePort (adjust the port as needed)
kubectl patch svc prometheus-grafana -n monitoring -p '{"spec": {"type": "NodePort", "ports": [{"port": 80, "nodePort": 30000, "targetPort": 3000}]}}'
