#!/bin/bash
set -exo pipefail
    echo "DATABASE ${ODOO_DB}"
    BACKUP_ARGS=()
    BACKUP_ARGS+=("--db_name")
    BACKUP_ARGS+=("${ODOO_DB}")

    BACKUP_ARGS+=("--master_password")
    BACKUP_ARGS+=("${MASTERDB_PASSWORD}")
    
    BACKUP_ARGS+=("--dest")
    BACKUP_ARGS+=("/backup")

    BACKUP_ARGS+=("--saas_manager")
    BACKUP_ARGS+=("${SAAS_MANAGER_URL}")

    BACKUP_ARGS+=("--pod_code")
    BACKUP_ARGS+=("${POD_CODE}")

    BACKUP_ARGS+=("--store_name")
    BACKUP_ARGS+=("${STNAME}")

    BACKUP_ARGS+=("--bucket_name")
    BACKUP_ARGS+=("${BUCKET_NAME}")

    BACKUP_ARGS+=("--subscription")
    BACKUP_ARGS+=("${SAAS_SUBSCRIPTION_NUM}")
    
    BACKUP_ARGS+=("--db_host")
    BACKUP_ARGS+=("${DBHOST}")
    
    BACKUP_ARGS+=("--db_port")
    BACKUP_ARGS+=("${DBPORT}")

    BACKUP_ARGS+=("--db_user")
    BACKUP_ARGS+=("${DBUSER}")
    

    BACKUP_ARGS+=("--db_password")
    BACKUP_ARGS+=("${DBPASSWORD}")

    echo "RESTORE ARGUMENTS: $@ ${BACKUP_ARGS[@]}"
cd /mnt/scripts
while : 
do
    #/mnt/scripts/postgres_backup.py ${BACKUP_ARGS[@]}  
    #/mnt/scripts/postgres_restore.py ${BACKUP_ARGS[@]}  
    /mnt/scripts/postgres_backup.py ${BACKUP_ARGS[@]}  
    sleep 30
done;