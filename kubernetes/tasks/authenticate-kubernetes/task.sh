#!/bin/bash

set -xu


pks login -a "$PKS_API_URL" -u "$PKS_API_USERNAME" -p "$PKS_API_PASSWORD" -k

k8s_master_ip=$(pks cluster "$PKS_CLUSTER_NAME" --json | jq -r ".kubernetes_master_ips | first")

pks get-credentials "$PKS_CLUSTER_NAME"

sed -i "s/server: .*$/server: https:\/\/"$k8s_master_ip":8443/" ~/.kube/config

kubectl cluster-info

cp ~/.kube/config kube-config/config

chmod 644 kube-config/config