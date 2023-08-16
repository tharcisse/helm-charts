#!/bin/bash
set -exo pipefail
rm -fr /mnt/data/*
cd /mnt/data

suffix=".git"
branchsuffix="branch"

echo "Main Repository ${MAIN_GIT} and main branch ${MAIN_GIT_BRANCH}"



if [[ "$MAIN_GIT" == "undefined" || "$MAIN_GIT_BRANCH" == "undefined" ]]; then
  echo "No repo defined"
elif [[ "$MAIN_GIT_TOKEN" != "undefined" ]]; then
    echo ${MAIN_GIT%"$suffix"}
    curl -sSL -u ${MAIN_GIT_TOKEN}:x-oauth-basic ${MAIN_GIT%"$suffix"}/tarball/${MAIN_GIT_BRANCH%"$branchsuffix"} | tar zxf - --strip-components=1
else
    curl -sSL ${MAIN_GIT%"$suffix"}/tarball/${MAIN_GIT_BRANCH%"$branchsuffix"} | tar zxf - --strip-components=1
fi

directory="addons"
if [ -d "$directory" ]
then
    cd addons
    set -f
    if [[ "$ODOO_EXTRA_MODULES" != "undefined" ]]; then
        array=($ODOO_EXTRA_MODULES)
        for i in "${array[@]}"; do
            if [ -d $i ]
            then
                echo $i
                FILE=${i}/requirements.txt
                if test -f "$FILE"; then
                    pip3 install -r ${i}/requirements.txt
                fi
                cp -R $i /mnt/extra-addons/
            fi
        done
    fi
    cd ../
    rm -r addons
fi