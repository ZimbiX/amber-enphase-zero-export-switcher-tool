#!/bin/bash

set -Eeuo pipefail

cd "$(dirname "$0")"

source ../.env

collect-current-readings() {
  curl \
    --silent \
    --insecure \
    -H "Authorization: Bearer $ZEST_ENPHASE_ENVOY_ACCESS_TOKEN" \
    "https://$ZEST_ENPHASE_ENVOY_IP/production.json?details=1" \
    | ruby -r json -r time -e "
        hash = JSON.parse(STDIN.read)

        production = hash['production']
        production_eim = production.find { _1['type'] == 'eim' }

        consumption = hash['consumption']
        consumption_eim_total_consumption = consumption.find { _1['type'] == 'eim' && _1['measurementType'] == 'total-consumption' }
        consumption_eim_net_consumption = consumption.find { _1['type'] == 'eim' && _1['measurementType'] == 'net-consumption' }

        puts [
          [
            'eim',
            Time.at(production_eim['readingTime']).iso8601,
            production_eim['wNow'],
          ].join(','),
          [
            'total-consumption',
            Time.at(consumption_eim_total_consumption['readingTime']).iso8601,
            consumption_eim_total_consumption['wNow'],
          ].join(','),
          [
            'net-consumption',
            Time.at(consumption_eim_net_consumption['readingTime']).iso8601,
            consumption_eim_net_consumption['wNow'],
          ].join(','),
          [
            'voltage',
            Time.at(consumption_eim_net_consumption['readingTime']).iso8601,
            consumption_eim_net_consumption['rmsVoltage'],
          ].join(','),
        ]
      " \
    >> ~/envoy.csv
}

while true; do
  collect-current-readings
  echo
  sleep 1
done
