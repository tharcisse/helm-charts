#!/bin/bash


bash /mnt/scripts/global_addons_import.sh
bash /mnt/scripts/custom_addons_import.sh
bash /mnt/scripts/requirements.sh
cd /mnt/scripts/
bash /mnt/scripts/entrypoint.sh odoo