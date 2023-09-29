#!/usr/bin/env python3
import argparse
import zipfile

if __name__ == '__main__':
    arg_parser = argparse.ArgumentParser()
    arg_parser.add_argument('--f', required=True)
    arg_parser.add_argument('--d', required=True)

    args = arg_parser.parse_args()

    with zipfile.ZipFile(args.f, 'r') as zip_ref:
        zip_ref.extractall(args.d)