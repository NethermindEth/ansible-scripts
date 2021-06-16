#!/bin/bash
set -e
if [ "$(wget -qSO- --max-redirect=0 time.google.com 2>&1 -T 2 -t 1 | grep Date: | cut -d' ' -f5-8)Z" != "Z" ]; then
   echo "Syncing with Google"
   sudo date -s "$(wget -qSO- --max-redirect=0 time.google.com 2>&1 | grep Date: | cut -d' ' -f5-8)Z"
elif [ "$(wget -qSO- --max-redirect=0 time.cloudflare.com 2>&1 -T 2 -t 1 | grep Date: | cut -d' ' -f5-8)Z" != "Z" ]; then
   echo "Syncing with Cloudflare"
   sudo date -s "$(wget -qSO- --max-redirect=0 time.cloudflare.com 2>&1 | grep Date: | cut -d' ' -f5-8)Z"
elif [ "$(wget -qSO- --max-redirect=0 time.windows.com 2>&1 -T 2 -t 1 | grep Date: | cut -d' ' -f5-8)Z" != "Z" ]; then
   echo "Syncing with Windows"
   sudo date -s "$(wget -qSO- --max-redirect=0 time.windows.com 2>&1 | grep Date: | cut -d' ' -f5-8)Z"
fi