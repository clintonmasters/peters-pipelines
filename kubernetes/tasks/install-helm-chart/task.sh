#!/bin/bash
#params:
#  CHART_NAME:
#  CHART_VALUES:
#  K8S_NAMESPACE:

set -xu

cp kube-config/config ~/.kube/config

echo $CHART_VALUES > values.yml

kubectl config set-context $(kubectl config current-context) --namespace=$K8S_NAMESPACE

helm install --name $K8S_NAMESPACE -f values.yml stable/$CHART_NAME


