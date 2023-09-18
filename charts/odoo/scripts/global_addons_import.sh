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
MODULESTODOWNLOAD="undefined"
if [[ "$ODOO_EXTRA_MODULES" != "undefined" ]]; then
    $MODULESTODOWNLOAD=$ODOO_EXTRA_MODULES
fi
if [[ "$SERVER_WIDE_MODULES" != "undefined" ]]; then
    if [[ "$MODULESTODOWNLOAD" != "undefined" ]]; then
        $MODULESTODOWNLOAD="${MODULESTODOWNLOAD} ${SERVER_WIDE_MODULES}"
    else
        $MODULESTODOWNLOAD=${SERVER_WIDE_MODULES}
    fi
fi
directory="addons"
if [ -d "$directory" ]
then
    cd addons
    set -f
    AV_EXTRA_MODULES=()
    if [[ "$ODOO_EXTRA_MODULES" != "undefined" ]]; then
        array=($ODOO_EXTRA_MODULES)
        for i in "${array[@]}"; do
            if [ -d $i ]
            then
                echo $i
                AV_EXTRA_MODULES+=($i)
                FILE=${i}/requirements.txt
                if test -f "$FILE"; then
                    pip3 install -r ${i}/requirements.txt
                fi
                cp -R $i /mnt/extra-addons/
            fi
        done
        ODOO_EXTRA_MODULES="${AV_EXTRA_MODULES[@]}"
    fi
    cd ../
    rm -r addons
fi
cd /mnt/extra-addons/
if [ -d "sub_controller" ]
then
    cd sub_controller/data/
    set -f
    sed -i "s/SAAS_NUM_OF_USER/${SAAS_NUM_OF_USER}/gi" config.xml
    sed -i "s/SAAS_MANAGER_URL/${SAAS_MANAGER_URL}/gi" config.xml
    sed -i "s/SAAS_SUBSCRIPTION_NUM/${SAAS_SUBSCRIPTION_NUM}/gi" config.xml
    sed -i "s/SAAS_SUBSCRIPTION_TRIAL/${SAAS_SUBSCRIPTION_TRIAL}/gi" config.xml
    sed -i "s/SAAS_SUBSCRIPTION_ENDATE/${SAAS_SUBSCRIPTION_ENDATE}/gi" config.xml
fi