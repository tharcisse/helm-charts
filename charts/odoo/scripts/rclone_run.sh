#!/bin/sh
set -exo pipefail
while :
do     
    echo "BUCKET $BUCKET_NAME PROVIDER $STNAME"
    if [[ "$BUCKET_NAME" != "undefined" && "$STNAME" != "undefined" ]]; then
        for f in $(find /backup/* -type f -mmin +2);
        do
            rclone sync -P $f ${STNAME}:${BUCKET_NAME}/${ODOO_DB}
            rm -f $f
            echo "Sent to Object Storage"  
            curl -X POST -H "Content-Type: application/json" -d "{\"namespace\": ${ODOO_DB},\"backup_name\": ${f},\"code\": ${POD_CODE}}" ${SAAS_MANAGER_URL}/backup_notifier
        done
        for f in $(find /restore/*.to_restore);
        do
            remote_file=
            rclone sync -P ${STNAME}:${BUCKET_NAME}/${ODOO_DB}/${f%"to_store"}.zip /restore/temp
            mv /restore/temp/* /restore/
            rm -f $f
            echo "restored to Object Storage"       
            curl -X POST -H "Content-Type: application/json" -d "{\"namespace\": ${ODOO_DB}, \"restore_name\": ${f},\"code\": ${POD_CODE}}" ${SAAS_MANAGER_URL}/restore_notifier
        done
        sleep 20
    fi
done