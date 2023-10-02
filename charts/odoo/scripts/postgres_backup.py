#!/usr/bin/env python3
from xmlrpc.client import ServerProxy as XMLServerProxy
import base64
import argparse
from datetime import datetime
import requests
import sys
import json

if __name__ == '__main__':
    arg_parser = argparse.ArgumentParser()
    arg_parser.add_argument('--db_name', required=True)
    arg_parser.add_argument('--master_password', required=True)
    arg_parser.add_argument('--dest', required=True)
    arg_parser.add_argument('--saas_manager', required=True)
    arg_parser.add_argument('--pod_code', required=True)
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
        notify = True
        date_str = datetime.now().strftime("%m%d%_Y%H%M%S")
        backup_name = args.db_name + '_' + date_str + '.zip'
        backup_full_name = args.dest + '/' + backup_name
        sock = XMLServerProxy('http://localhost:8069/xmlrpc/db')
        backup_file = open(backup_full_name, 'wb')
        backup_file.write(base64.b64decode(sock.dump(args.master_password, args.db_name, 'zip')))
        backup_file.close()
        print('Backup file created')

    if response.get('data', {}).get('restore_requested', False):
        restore_file = response.get('data', {}).get('restore_name', '')
        restore_file = restore_file.replace('.zip', 'to_restore')
        if restore_file:
            restore = open('/restore/' + restore_file, 'w')
            restore.write('Waiting')
            restore.close()
            print('Pending a restore')
