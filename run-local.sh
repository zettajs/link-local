#!/bin/bash

set -e

BASE=3000
if [ "$1" != "" ]; then BASE=$1; fi;

SERVICE_REGISTRY_PORT=$((BASE + 0))

export COREOS_PUBLIC_IPV4=127.0.0.1
export COREOS_PRIVATE_IPV4=localhost
export JWT_PLAIN_TEXT="abc,123"

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
start_target $((BASE + 101))
#start_target $((BASE + 102))

sleep 1;

PORT=2000 node link-tenant-mgmt-api/server.js &

PORT=$((BASE + 0)) TENANT_MANAGEMENT_API="http://localhost:2000" node zetta-cloud-proxy/proxy_server.js &
ROUTER_PID=$!

wait;
