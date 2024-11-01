#!/bin/bash

set -exo pipefail

TIKV_POD_FQDNs=$(echo "${TIKV_POD_FQDN_LIST}" | tr ',' '\n')
TIKV_ADDRESS=$(echo "$TIKV_POD_FQDNs" | grep "$CURRENT_POD_NAME")
echo "$TIKV_ADDRESS"
/pd-ctl -u "$PD_ADDRESS" store delete addr "$TIKV_ADDRESS"

until [ $(/pd-ctl -u "$PD_ADDRESS" store | jq "any(.stores[]; select(.store.address == \"$TIKV_ADDRESS\"))") == "false" ]
do
    echo "waiting for tikv node to become tombstone"
    sleep 10
done

echo "removing tombstone"
/pd-ctl -u "$PD_ADDRESS" store remove-tombstone
