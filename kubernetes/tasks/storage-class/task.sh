#!/bin/bash

set -xu

cp kube-config/config ~/.kube/config

# TODO: Fix this later to support other IaaS
# https://docs.pivotal.io/runtimes/pks/1-2/volumes.html
#$ wget https://raw.githubusercontent.com/cloudfoundry-incubator/kubo-ci/master/specs/storage-class-gcp.yml
#$ wget https://raw.githubusercontent.com/cloudfoundry-incubator/kubo-ci/master/specs/storage-class-aws.yml


cat << EOF > storageclass.yaml
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: thin
  annotations:
      storageclass.kubernetes.io/is-default-class: "true"
provisioner: kubernetes.io/vsphere-volume
parameters:
  diskformat: thin
EOF

kubectl create -f storageclass.yaml

