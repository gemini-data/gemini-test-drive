#!/bin/sh
source 0_env.sh


zip adapter.zip application.conf model.json
./sshpass -p $CONFIG_PASS scp -o 'StrictHostKeyChecking no' -P 2222 adapter.zip $CONFIG_USER@$PUBLIC_IP:/project/data
curl "http://$MASTER_IP/service/marathon/v2/apps/zero-copy/adapter/restart" -X POST
rm -f adapter.zip
