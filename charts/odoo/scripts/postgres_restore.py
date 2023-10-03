#!/usr/bin/env python3

from xmlrpc.client import ServerProxy as XMLServerProxy
import base64
import argparse
import requests
from datetime import datetime
import requests
import json
import os

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

    directory = '/restore'
    sock = XMLServerProxy('http://localhost:8069/xmlrpc/db')
    restore_name = ''
    for filename in os.listdir(directory):
        print('Start restoring')
        if '.zip' in filename:
            print(f"Restore file found {filename}" )
            restore_name = filename
            file_full_name = os.path.join(directory, filename)
            restore_file = open(file_full_name, 'rb')
            restored=False
            try:
                sock.drop(args.master_password,args.db_name)
            except Exception as error:
                print(error)

            try:
                sock.restore(args.master_password, args.db_name, base64.b64encode(restore_file.read()).decode())
                restored=True
            except Exception as error:
                print(error)

            restore_file.close()
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
   
