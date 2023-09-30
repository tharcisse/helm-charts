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
    if [[ "$SERVER_WIDE_MODULES" != "undefined" ]]; then
        array=($SERVER_WIDE_MODULES)
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
cd /mnt/extra-addons/
if [ -d "sub_controller" ]
then
    cd sub_controller/data/
    set -f
    awk -v vPOD_CODE="$POD_CODE" '{gsub("POD_CODE",vPOD_CODE); print}' config.xml  > config2.xml && mv config2.xml config.xml
    awk -v vSAAS_MANAGER_URL="$SAAS_MANAGER_URL" '{gsub("SAAS_MANAGER_URL",vSAAS_MANAGER_URL); print}' config.xml  > config2.xml && mv config2.xml config.xml
    awk -v vSAAS_SUBSCRIPTION_NUM="$SAAS_SUBSCRIPTION_NUM" '{gsub("SAAS_SUBSCRIPTION_NUM",vSAAS_SUBSCRIPTION_NUM); print}' config.xml  > config2.xml && mv config2.xml config.xml
    awk -v vSAAS_SUBSCRIPTION_TRIAL="$SAAS_SUBSCRIPTION_TRIAL" '{gsub("SAAS_SUBSCRIPTION_TRIAL",vSAAS_SUBSCRIPTION_TRIAL); print}' config.xml  > config2.xml && mv config2.xml config.xml
    awk -v vSAAS_SUBSCRIPTION_ENDATE="$SAAS_SUBSCRIPTION_ENDATE" '{gsub("SAAS_SUBSCRIPTION_ENDATE",vSAAS_SUBSCRIPTION_ENDATE); print}' config.xml  > config2.xml && mv config2.xml config.xml
fi