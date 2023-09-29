#!/bin/bash
set -exo pipefail
pip3 install requests
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
while : 
do
    /mnt/scripts/postgres_backup.py ${BACKUP_ARGS[@]}  
    sleep 1m
done;