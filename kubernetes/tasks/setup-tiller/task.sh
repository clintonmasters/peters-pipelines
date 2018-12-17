#!/bin/bash

set -xu

mkdir -m 700 -p ~/.kube
cp kube-config/config ~/.kube/config

cat << EOF > rbac-config.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: tiller
  namespace: kube-system
---
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRoleBinding
metadata:
  name: tiller
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
  - kind: ServiceAccount
    name: tiller
    namespace: kube-system
EOF

kubectl create -f rbac-config.yaml

# helm and tiller are in / in the offical image
if [[ -x /helm ]]; then
  export PATH=/:$PATH
fi

helm init --service-account tiller
