#!/usr/bin/env python3

from xmlrpc.client import ServerProxy as XMLServerProxy
import base64
import argparse
import requests
from datetime import datetime
import requests
import json
import os
import shutil
from .postgres_manager import restore_postgres_db

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

    directory = '/restore'
    sock = XMLServerProxy('http://localhost:8069/xmlrpc/db')
    restore_name = ''
    for filename in os.listdir(directory):
        if '.zip' in filename:
            print(f"Restore file found {filename}" )
            try:
                print('Backup started')
                date_str = datetime.now().strftime("%m%d%_Y%H%M%S")
                backup_name = args.db_name + '_' + date_str + '.zip'
                backup_full_name = args.dest + '/' + backup_name
                backup_file = open(backup_full_name, 'wb')
                backup_file.write(base64.b64decode(sock.dump(args.master_password, args.db_name, 'zip')))
                backup_file.close()
                print('Backup file created')
                sock.drop(args.master_password,args.db_name)
                print('DB Dropped')
            except Exception as error:
                print('Error dropping DB')
                print(error)
            restore_name = filename
            file_full_name = os.path.join(directory, filename)
            restored=False
            try:
                inner_directory= filename.rstrip('.zip')
                shutil.unpack_archive(file_full_name,'/dbrestore/' + inner_directory)
                shutil.copytree('/dbrestore/' + inner_directory + 'filestore', '/datadir', dirs_exist_ok=True)
                restore_postgres_db(args.db_host, args.db_name, args.db_port, args.db_user, args.db_password, '/dbrestore/' + inner_directory + 'dump.sql', True)

            except Exception as error:
                print('Error restoring DB')
                print(error)

            
            try:
                if restored:
                    os.remove(file_full_name)
            except OSError:
                pass
            
            if restored:
                payload={
                "namespace": args.db_name, "restore_name": filename,"code": args.pod_code
                }
                requests.post(args.saas_manager + '/restore_notifier', json=payload,
                                headers={'content-Type': 'application/json'}, timeout=60)
   
