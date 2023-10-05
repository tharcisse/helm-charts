#!/bin/sh

index=6
while :
do
    echo $(ls -l /var/lib)
    /bin/chmod -R 777 /var/lib/odoo
    if [ -w "/var/lib/odoo" ]; then 
        echo "WRITABLE"; 
        echo $(ls -l /var/lib)
        break;
    fi
    if [ "$index"  -le "0" ]; then
        break;
    fi
    sleep 10
    let "index--"
done