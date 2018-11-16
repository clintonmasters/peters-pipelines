#!/bin/bash

set -xu

cp kube-config/config ~/.kube/config

kubectl apply -f pks-prometheus/loadBalancer.yml -n $K8S_NAMESPACE

kubectl get services -n $K8S_NAMESPACE

while [ 1 ]
do
    loadBalancer_ip=$(kubectl get services -n ${K8S_NAMESPACE} -o json | jq -r ' .items[] | select(.metadata.name == "prometheus-service") | .status.loadBalancer.ingress[0].ip')
    echo $loadBalancer_ip
    if [ "$loadBalancer_ip" = "" ]
    then
        echo "Checking again..."
    else
        echo "Check out your Prometheus Dashboard! http://$loadBalancer_ip:8080"
        exit 0 
    fi
    sleep 3
done