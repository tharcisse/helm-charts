#!/usr/bin/env python3

from xmlrpc.client import Transport as XMLTransport
from xmlrpc.client import SafeTransport as XMLSafeTransport
from xmlrpc.client import ServerProxy as XMLServerProxy
from xmlrpc.client import _Method as XML_Method 
import base64
import argparse
from datetime import datetime
import requests

if __name__ == '__main__':
    arg_parser = argparse.ArgumentParser()
    arg_parser.add_argument('--db_name', required=True)
    arg_parser.add_argument('--master_password', required=True)
    arg_parser.add_argument('--dest', required=True)
    arg_parser.add_argument('--saas_manager', required=True)
    #arg_parser.add_argument('--notify', required=True)
    notify = False

    args = arg_parser.parse_args()
    payload = {
        'namespace': args.db_name,
        'code': args.pod_code
    }
    response = requests.get(args.saas_manager + '/backup_checker', json=payload,
                            headers={'content-Type': 'application/json'}, timeout=60)
    do_backup = False
    if response.status_code == 200:
        response = response.json()
        print(response)
        if response.get('backup_requested', False):
            do_backup = True
    if not do_backup:
        print('No backup requested')
    else:    
        notify=True
        date_str = datetime.now().strftime("%m%d%_Y%H%M%S")
        backup_name = args.dest + '/' + args.db_name + '_' + date_str + '.zip'
        sock = XMLServerProxy('http://localhost:8069/xmlrpc/db')
        backup_file = open(backup_name, 'wb')
        backup_file.write(base64.b64decode(sock.dump(args.master_password, args.db_name)))
        backup_file.close()

        if notify:
            payload = {
                'namespace': args.db_name,
                'backup_name': backup_name,
                'code': args.pod_code
            }
            requests.post(args.saas_manager + '/backup_notifier', json=payload, timeout=60)
