#!/usr/bin/env python3

from xmlrpc.client import ServerProxy as XMLServerProxy
import base64
import argparse
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
        if '.zip' in filename:
            restore_name = filename
            restore_file = open(os.path.join(directory, filename), 'rb')
            sock.restore(args.master_password, args.db_name, base64.b64encode(restore_file.read()).decode())
            restore_file.close()
            notify = True
    if notify:
        print('File restored')
        payload = {
            'namespace': args.db_name,
            'retore_name': restore_name,
            'code': args.pod_code
        }
        requests.post(args.saas_manager + '/restore_notifier', json=payload, timeout=60)
