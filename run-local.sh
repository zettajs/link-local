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

export COREOS_PUBLIC_IPV4=127.0.0.1
export COREOS_PRIVATE_IPV4=localhost
export JWT_PLAIN_TEXT="abc,123"
export INFLUXDB_HOST=localhost

function start_target() {
    local port=$1
    MAPPED_PORT=$port node target_wrapper.js &
    echo "Target: $!"
}

if [ "$1" == "" ]; then
    echo "Starting ETCD"
    rm -R -f default.etcd
    ETCD_PID=""
    function cleanup {
        echo "Cleanup"
        sleep 5;
        kill $ETCD_PID
    }

    trap cleanup EXIT
    etcd --force-new-cluster 2> /dev/null &
    ETCD_PID=$(pidof etcd)

    sleep 3;
    etcdctl set /zetta/version '{"version": "0"}'
    etcdctl mkdir /services/zetta
fi

start_target $((BASE + 100))
#start_target $((BASE + 101))
#start_target $((BASE + 102))

sleep 1;

#PORT=2000 node link-tenant-mgmt-api/server.js &

PORT=$((BASE + 0)) TENANT_MANAGEMENT_API="http://localhost:2000" node zetta-cloud-proxy/proxy_server.js &
ROUTER_PID=$!

wait;
