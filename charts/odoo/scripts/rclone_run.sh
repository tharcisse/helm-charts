#!/bin/sh
set -exo pipefail
apk add --update curl
while :
do     
    echo "BUCKET $BUCKET_NAME PROVIDER $STNAME"
    if [[ "$BUCKET_NAME" != "undefined" && "$STNAME" != "undefined" ]]; then
        for f in $(find /backup/* -type f -mmin +1);
        do
            filename=${f#"/backup/"}
            rclone sync -P $f ${STNAME}:${BUCKET_NAME}/${SAAS_SUBSCRIPTION_NUM}
            rm -f $f
            echo "Sent to Object Storage"  
            curl -X POST -H "Content-Type: application/json" -d "{\"namespace\": \"${ODOO_DB}\",\"backup_name\": \"${filename}\",\"code\": \"${POD_CODE}\"}" ${SAAS_MANAGER_URL}/backup_notifier
        done
        for f in $(find /restore/*.to_restore);
        do
            filetorestore=${f#"/restore/"}
            filename=${filetorestore%".to_restore"}
            rclone sync -P ${STNAME}:${BUCKET_NAME}/${SAAS_SUBSCRIPTION_NUM}/${filename}.zip /restore/temp
            mv /restore/temp/* /restore/
            rm -f $f
            echo "restored to Object Storage"       
        done
        sleep 20
    fi
done