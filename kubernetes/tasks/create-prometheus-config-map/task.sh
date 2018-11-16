#!/bin/bash

set -xu

cp kube-config/config ~/.kube/config

echo "  namespace: $K8S_NAMESPACE" >> pks-prometheus/configMap.yml

kubectl apply -f pks-prometheus/configMap.yml -n $K8S_NAMESPACE

kubectl get configmaps -n $K8S_NAMESPACE