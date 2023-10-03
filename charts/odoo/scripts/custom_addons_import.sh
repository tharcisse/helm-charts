#!/bin/bash
set -exo pipefail
rm -fr /mnt/data/*
cd /mnt/data
mkdir -p custom

suffix=".git"
branchsuffix="branch"
echo "Custom Repository ${CUSTOM_GIT} and Custom branch ${CUSTOM_GIT_BRANCH}"
mkdir -p zipcustom
#if [[ "$SAAS_DEPLOYMENT_HASH" && "$SAAS_MANAGER_URL" ]] then
curl -o ${SAAS_DEPLOYMENT_HASH}.zip ${SAAS_MANAGER_URL}/custom_modules?code=${SAAS_DEPLOYMENT_HASH}
/mnt/scripts/unzip.py --f ${SAAS_DEPLOYMENT_HASH}.zip --d zipcustom
ls zipcustom
for z in zipcustom/*.zip; do
    echo "$z"
    if [[ "$z" != "zipcustom/*.zip" ]]; then
        /mnt/scripts/unzip.py --f "$z" --d custom; 
    fi
done
rm -r zipcustom
rm -f ${SAAS_DEPLOYMENT_HASH}.zip
cd custom

if [[ "$CUSTOM_GIT" == "undefined" || "$CUSTOM_GIT_BRANCH" == "undefined" || -z "$CUSTOM_GIT" || -z  "$CUSTOM_GIT_BRANCH" ]]; then
    echo "No repo defined"
elif [[ "$CUSTOM_GIT_TOKEN" != "undefined" ]]; then
    curl -sSL -u ${CUSTOM_GIT_TOKEN}:x-oauth-basic ${CUSTOM_GIT%"$suffix"}/tarball/${CUSTOM_GIT_BRANCH%"$branchsuffix"} | tar zxf - --strip-components=1
else
    curl -sSL ${CUSTOM_GIT%"$suffix"}/tarball/${CUSTOM_GIT_BRANCH%"$branchsuffix"} | tar zxf - --strip-components=1
fi

echo copy all custom modules

FILE=requirements.txt
if test -f "$FILE"; then
    pip3 install -r ${FILE}
fi
CU_EXTRA_MODULES=()
cp -R * /mnt/extra-addons
for i in * ; do
    if [ -d $i ]
    then
        echo $i
        if test -f ${i}/${FILE}; then
            pip3 install -r ${i}/${FILE}
        fi      
        CU_EXTRA_MODULES+=($i)
    fi
done
if [ -n "$CU_EXTRA_MODULES" ]; then
    if [[ "$ODOO_EXTRA_MODULES" != "undefined" ]];then

        ODOO_EXTRA_MODULES+=",${CU_EXTRA_MODULES[@]}"
    fi
fi
cd ../
rm -r custom