#!/bin/bash

set -xu

cp kube-config/config ~/.kube/config

kubectl apply -f pks-prometheus/clusterRole.yml -n $K8S_NAMESPACE

kubectl get clusterroles -n $K8S_NAMESPACE

kubectl get clusterrolebindings -n $K8S_NAMESPACE