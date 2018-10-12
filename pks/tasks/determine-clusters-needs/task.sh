#!/bin/bash

set -u

cp pks-config/creds.yml ~/.pks/creds.yml
cd pks-clusters

pks clusters --json > current.json

printf "\n\nCURRENT STATE: \n"
cat current.json
printf "\n\nDESIRED STATE: \n"
cat ${PKS_CLUSTER_JSON_FILE}

set -x
pks-diff -current current.json -desired ${PKS_CLUSTER_JSON_FILE}

set +x
printf "\n\nSTEPS TO GET TO DESIRED STATE: \n"
cat pksRun.sh

git config user.email "pks-bot@pivotal.io"
git config user.name "pks-bot"
git add .
git commit -m "Add Run Script For Getting Back To Desired State"