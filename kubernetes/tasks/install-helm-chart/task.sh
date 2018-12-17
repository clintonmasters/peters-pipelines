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

cp kube-config/config ~/.kube/config

helm init --client-only

HELM_OPTIONS="stable/$CHART_NAME"

# Set chart values from file if CHART_VALUES exists
FILE=${CHART_VALUES:-novalues}
if [[ "$FILE" != "novalues" ]]; then
  HELM_OPTIONS="-f \"$CHART_VALUES\" stable/$CHART_NAME"
fi

# Install the Chart
helm upgrade $RELEASE_NAME $CHART_NAME --install --values $HELM_OPTIONS


