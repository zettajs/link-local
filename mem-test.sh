#!/bin/bash -eu
#
# Copyright 2018 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

#!/bin/bash

set -e

BASE=3000
if [ "$1" != "" ]; then BASE=$1; fi;

SERVICE_REGISTRY_PORT=$((BASE + 0))

export COREOS_PRIVATE_IPV4=localhost

function start_target() {
    local port=$1
    MAPPED_PORT=$port node target_wrapper.js > /dev/null 2> /dev/null &
}

if [ "$1" == "" ]; then
    rm -R -f default.etcd
    ETCD_PID=""
    function cleanup {
        echo "Cleanup"
        sleep 2;
        kill $ETCD_PID
    }

    trap cleanup EXIT
    etcd --force-new-cluster 2> /dev/null &
    ETCD_PID=$(pidof etcd)

    sleep 3;
    etcdctl set /zetta/version '{"version": "0"}'
    etcdctl mkdir /services/zetta
    etcdctl mkdir /router/zetta/default
fi

start_target $((BASE + 100))
#start_target $((BASE + 101))
#start_target $((BASE + 102))

sleep 1;

PORT=2000 node link-tenant-mgmt-api/server.js  > /dev/null 2> /dev/null &

PORT=$((BASE + 0)) TENANT_MANAGEMENT_API="http://localhost:2000" node zetta-cloud-proxy/proxy_server.js  > /dev/null 2> /dev/null &
ROUTER_PID=$!


while true; do
    actualCount=$(etcdctl ls /router/zetta/default | while read l; do name=$(etcdctl get $l | jq -r .name); curl -f -L -s http://localhost:3000/servers/$name > /dev/null; if [ "$?" == "0" ]; then echo $name; fi done | wc -l | sed 's/^ *//')
    count=$(etcdctl ls /router/zetta/default | wc -l | sed 's/^ *//')
    mem=`ps -o rss -p $ROUTER_PID | sed -n '1!p' | sed 's/^ *//'`
    date=$(date +%s);
    
    echo "$date,$mem,$count,$actualCount";
    
    sleep 5;

done

wait;
