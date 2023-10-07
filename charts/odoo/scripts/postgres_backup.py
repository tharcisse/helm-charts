#!/usr/bin/env python3
from xmlrpc.client import ServerProxy as XMLServerProxy
import base64
import argparse
from datetime import datetime
import requests
import sys
import os
import json
from rclone_python import rclone, remote_types
from rclone_python.hash_types import HashTypes
from postgres_manager import swap_restore_active
import shutil


def swap_filestore(db_from, db_to):
    print("Swap Filestore")
    # swap filestores
    curr_filestore = '/datadir' + '/filestore/' + db_to
    temp_filestore = '/datadir' + '/filestore/' + db_from
    print("Current filestore:" + curr_filestore)

    if restored:
        try:
            if os.path.exists(curr_filestore) and os.path.exists(temp_filestore):
                print('Found filestore path')
                shutil.rmtree(curr_filestore)
                shutil.move(temp_filestore, curr_filestore)
        except Exception as error:
            print(error)
            print('Could Not swap filestores')
    print('Restore swapped')


def odoo_backup(args):
    backedup = False
    reason = ""
    try:
        date_str = datetime.now().strftime("%m%d%_Y%H%M%S")
        backup_name = args.db_name + '_' + date_str + '.zip'
        backup_full_name = args.dest + '/' + backup_name
        sock = XMLServerProxy('http://localhost:8069/xmlrpc/db')
        backup_file = open(backup_full_name, 'wb')
        backup_file.write(base64.b64decode(sock.dump(args.master_password, args.db_name, 'zip')))
        backup_file.close()
        print('Backup file created')
        print('Loading to S3')
        rclone.copy(backup_full_name, args.store_name + ":" + args.bucket_name + "/" + args.subscription)
        print('Finished loadng to S3')
        backedup = True
    except Exception as error:
        print(error)
        reason = str(error)

    try:
        os.remove(backup_full_name)
    except OSError:
        pass
    payload = {
        "namespace": args.db_name,
        "backup_name": backup_name,
        "code": args.pod_code,
        "op_status": backedup,
        "reason": reason
    }
    requests.post(args.saas_manager + '/backup_notifier', json=payload,
                  headers={'content-Type': 'application/json'}, timeout=60)


if __name__ == '__main__':
    arg_parser = argparse.ArgumentParser()
    arg_parser.add_argument('--db_name', required=True)
    arg_parser.add_argument('--master_password', required=True)
    arg_parser.add_argument('--dest', required=True)
    arg_parser.add_argument('--saas_manager', required=True)
    arg_parser.add_argument('--pod_code', required=True)
    arg_parser.add_argument('--store_name', required=True)
    arg_parser.add_argument('--bucket_name', required=True)
    arg_parser.add_argument('--subscription', required=True)

    arg_parser.add_argument('--db_host', required=True)
    arg_parser.add_argument('--db_port', required=True)
    arg_parser.add_argument('--db_user', required=True)
    arg_parser.add_argument('--db_password', required=True)
    #arg_parser.add_argument('--notify', required=True)
    notify = False

    args = arg_parser.parse_args()
    payload = {
        'namespace': args.db_name,
        'code': args.pod_code
    }
    try:
        response = requests.get(args.saas_manager + '/backup_checker', json=payload,
                                headers={'content-Type': 'application/json'}, timeout=60)
    except Exception as error:
        print(error)
        sys.exit(1)

    do_backup = False
    try:
        response = response.json()
        if response.get('status', 404) == 200:
            if response.get('data', {}).get('backup_requested', False):
                do_backup = True
    except Exception as error:
        print(error)

    if not do_backup:
        print('No backup requested')
    else:
        print('Backup started')
        odoo_backup(args)

    if response.get('data', {}).get('restore_requested', False):
        restore_file_name = response.get('data', {}).get('restore_name', '')
        restored = False
        print('Dowload restore from S3')
        try:
            rclone.copy(args.store_name + ":" + args.bucket_name + "/" + args.subscription + '/' + restore_file_name, '/restore')
        except Exception as error:
            print(error)
        file_full_name = os.path.join('/restore', restore_file_name)
        restore_file = open(file_full_name, 'rb')

        odoo_backup(args)
        try:
            sock = XMLServerProxy('http://localhost:8069/xmlrpc/db')
            sock.restore(args.master_password, args.db_name+'_restore', base64.b64encode(restore_file.read()).decode())

        except Exception as error:
            print(error)
        restore_file.close()
        print('Restore Loaded')

        try:
            swap_restore_active(args.db_host, args.db_name+'_restore', args.db_name,
                                args.db_port, args.db_user, args.db_password)
            restored = True
        except Exception as error:
            print(error)

        if restored:
            swap_filestore(args.db_name+'_restore', args.db_name)

        try:
            os.remove(file_full_name)
        except OSError:
            pass
        reason = ""

        payload = {
            "namespace": args.db_name,
            "restore_name": restore_file_name,
            "code": args.pod_code,
            "restore_status": restored,
            "reason": reason
        }
        print(payload)
        requests.post(args.saas_manager + '/restore_notifier', json=payload,
                      headers={'content-Type': 'application/json'}, timeout=60)
    if response.get('data', {}).get('import_requested', False):
        import_db_name = response.get('data', {}).get('import_name', '')

        try:
            swap_restore_active(args.db_host, import_db_name, args.db_name,
                                args.db_port, args.db_user, args.db_password)
            imported = True
        except Exception as error:
            print(error)
            reason = str(error)
        if imported:
            swap_filestore(import_db_name, args.db_name)
            payload = {
                "namespace": args.db_name,
                "import_name": import_db_name,
                "code": args.pod_code,
                "status": imported,
                "reason": reason
            }
            print(payload)
            requests.post(args.saas_manager + '/import_notifier', json=payload,
                          headers={'content-Type': 'application/json'}, timeout=60)
