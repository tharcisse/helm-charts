#!/bin/sh
set -exo pipefail
while True:
do     
    if [[ "$BUCKET_NAME" != "undefined" && "$PROVIDER" != "undefined" ]] then
        for f in $(find /backup/* -type f -mmin +3)
        do
            rclone sync -P $f ${PROVIDER}:${BUCKET_NAME}/{{.Values.namespace}}
            rm -f $f       
        done
        sleep 5m
    fi
done