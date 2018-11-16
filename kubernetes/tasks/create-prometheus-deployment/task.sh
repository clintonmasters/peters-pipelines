#!/bin/bash

set -xu

cp kube-config/config ~/.kube/config

kubectl apply -f pks-prometheus/deployment.yml -n $K8S_NAMESPACE

kubectl get deployments -n $K8S_NAMESPACE