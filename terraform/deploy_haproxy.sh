#!/bin/bash

# Create HAProxy ConfigMap and Deployment
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: haproxy-config
  namespace: default
data:
  haproxy.cfg: |
    defaults
      log global
      mode tcp
      option tcplog
      timeout connect 10s
      timeout client 1m
      timeout server 1m

    frontend k8s
      bind *:6443
      default_backend k8s-masters

    backend k8s-masters
      balance roundrobin
      server master1 $MASTER_NODE_IP:6443 check

---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: haproxy
  namespace: default
spec:
  replicas: 1
  selector:
    matchLabels:
      app: haproxy
  template:
    metadata:
      labels:
        app: haproxy
    spec:
      containers:
      - name: haproxy
        image: haproxy:2.6
        volumeMounts:
        - name: haproxy-config
          mountPath: /usr/local/etc/haproxy/haproxy.cfg
          subPath: haproxy.cfg
      volumes:
      - name: haproxy-config
        configMap:
          name: haproxy-config
EOF
