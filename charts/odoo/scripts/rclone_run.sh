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
        done
        for f in $(find /restore/*.to_restore);
        do
            remote_file=
            rclone sync -P ${STNAME}:${BUCKET_NAME}/${ODOO_DB}/${f%"to_store"}.zip /restore/temp
            mv /restore/temp/* /restore/
            rm -f $f
            echo "restored to Object Storage"       
        done
        sleep 20
    fi
done