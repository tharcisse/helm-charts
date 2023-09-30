#!/bin/sh
set -exo pipefail
while :
do     
    echo "BUCKET $BUCKET_NAME PROVIDER $STNAME"
    if [[ "$BUCKET_NAME" != "undefined" && "$STNAME" != "undefined" ]]; then
        for f in $(find /backup/* -type f -mmin +3);
        do
            rclone sync -P $f ${STNAME}:${BUCKET_NAME}/${ODOO_DB}
            rm -f $f       
        done
        sleep 2m
    fi
done