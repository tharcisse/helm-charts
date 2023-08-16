#!/bin/bash
set -exo pipefail
rm -fr /mnt/data/*
cd /mnt/data
mkdir -p custom
cd custom
suffix=".git"
branchsuffix="branch"
echo "Custom Repository ${CUSTOM_GIT} and Custom branch ${CUSTOM_GIT_BRANCH}"

if [[ "$CUSTOM_GIT" == "undefined" || "$CUSTOM_GIT_BRANCH" == "undefined" ]]; then
  echo "No repo defined"
elif [[ "$CUSTOM_GIT_TOKEN" != "undefined" ]]; then
    curl -sSL -u ${CUSTOM_GIT_TOKEN}:x-oauth-basic ${CUSTOM_GIT%"$suffix"}/tarball/${CUSTOM_GIT_BRANCH%"$branchsuffix"} | tar zxf - --strip-components=1
    
    FILE=requirements.txt
    if test -f "$FILE"; then
        pip3 install -r requirements.txt
    fi
    cp -R * /mnt/extra-addons
    cd ../
    rm -r custom
else
    curl -sSL ${CUSTOM_GIT%"$suffix"}/tarball/${CUSTOM_GIT_BRANCH%"$branchsuffix"} | tar zxf - --strip-components=1
    FILE=requirements.txt
    if test -f "$FILE"; then
        pip3 install -r requirements.txt
    fi
    cp -R * /mnt/extra-addons
    cd ../
    rm -r custom
fi