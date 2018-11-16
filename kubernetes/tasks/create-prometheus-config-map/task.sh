#!/bin/bash

set -xu

cp kube-config/config ~/.kube/config

kubectl apply -f pks-prometheus/configMap.yml -n $K8S_NAMESPACE

kubectl get configmaps -n $K8S_NAMESPACE