#!/bin/sh
#params:
#  CHART_NAME:
#  CHART_VALUES:
#  K8S_NAMESPACE:

set -xu

# helm and tiller are in / in the image
if [[ -x /helm ]]; then
  export PATH=/:$PATH
fi

echo $PWD

mkdir -m 700 -p ~/.kube
cp kube-config/config ~/.kube/config

#helm init --client-only

# Set chart values from file if CHART_VALUES exists
FILE=${CHART_VALUES:-novalues}

if [[ "$FILE" == "novalues" ]]; then
  HELM_OPTIONS=""
else
  HELM_OPTIONS="--values \"$CHART_VALUES\""
fi

# Install the Chart
#helm upgrade $RELEASE_NAME stable/$CHART_NAME --install $HELM_OPTIONS


