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
            print(f"Resore file found {filename}" )
            restore_name = filename
            file_full_name = os.path.join(directory, filename)
            restore_file = open(file_full_name, 'rb')
            sock.restore(args.master_password, args.db_name, base64.b64encode(restore_file.read()).decode())
            restore_file.close()
            try:
                os.remove(file_full_name)
            except OSError:
                pass
            notify = True
   
