#!/bin/bash

set -e

target_count=1
verbose=0

while getopts "hv?t:r:" opt; do
    case "$opt" in
        h|\?)
            echo "Usage:"
            echo " -h: Show help"
            echo " -t <n>: Number of targets to start"
            exit 0
            ;;
        t)  target_count=$OPTARG
            ;;
        v)  verbose=1
            ;;
    esac
done

shift $((OPTIND-1))

function build {
    _working=`pwd`;
    echo "   - Building link-router"
    cd link-router/ && ./build.sh > /dev/null && cd $_working
    echo "   - Building link-zetta-target"
    cd link-zetta-target/ && ./build.sh > /dev/null && cd $_working
    echo "   - Building target-wrapper"
    cd target-wrapper/ && ./build.sh > /dev/null && cd $_working
    echo "   - Building link-tenant-mgmt-api"
    cd link-tenant-mgmt-api/ && ./build.sh > /dev/null && cd $_working
}

function cleanup {
    echo "Cleaning Up"
    for i in `seq 1 $target_count`;
    do
        docker rm -f zetta.target.$i > /dev/null
    done
    docker rm -f etcd link-router tenant-mgmt-api > /dev/null
}
trap cleanup EXIT

# Build all containers
echo "Building Containers"
build
echo ""

echo "Starting Services"
# Start Etcd
echo "  - Etcd"
docker run -d -p 4001:4001 -p 7001:7001 -p 2379:2379 -p 2380:2380 --name etcd elcolio/etcd:latest -name etcd -advertise-client-urls http://etcd:4001,http://localhost:4001,http://etcd:2379 > /dev/null
sleep 2

# Setup Etcd Dirs
docker run --rm --link etcd -e ETCDCTL_PEERS="http://etcd:4001" peopleperhour/etcdctl set /zetta/version '{"version": "0"}' > /dev/null
docker run --rm --link etcd -e ETCDCTL_PEERS="http://etcd:4001" peopleperhour/etcdctl mkdir /services/zetta > /dev/null

target_env_file=.target.env
echo "" > $target_env_file
echo "ZETTA_STACK=docker-local" >> $target_env_file
echo "LINK_INSTANCE_TYPE=target" >> $target_env_file
echo "INFLUXDB_HOST=influxdb" >> $target_env_file
echo "ETCD_PEER_HOSTS=etcd:4001" >> $target_env_file

# Start Targets
target_links=""
for i in `seq 1 $target_count`;
do
    port=`expr $i + 3000`;
    target_links="--link zetta.target.$i $target_links"
    echo "  - Target $i of $target_count on port $port"
    docker run -d --link etcd --name zetta.target.$i --env-file $target_env_file -e COREOS_PRIVATE_IPV4=zetta.target.$i -p $port:$port -e VERSION=0 -e MAPPED_PORT=$port zetta/zetta-target-server-wrapper > /dev/null
done

sleep 2;

# Start Routers
router_env_file=.router.env
echo "" > $router_env_file
echo "ZETTA_STACK=docker-local" >> $router_env_file
echo "LINK_INSTANCE_TYPE=router" >> $router_env_file
echo "INFLUXDB_HOST=influxdb" >> $router_env_file
echo "ETCD_PEER_HOSTS=etcd:4001" >> $router_env_file

echo "  - Link Router"
docker run -d --name link-router --link etcd $target_links --env-file $router_env_file -e PORT=3000 -p 3000:3000 zetta/zetta-cloud-proxy > /dev/null

echo "  - Tenant Management Api"
docker run -d --name tenant-mgmt-api --link etcd $target_links -e ETCD_PEER_HOSTS="etcd:4001" -p 2000:2000 zetta/link-tenant-mgmt-api > /dev/null

echo ""
echo ""
echo "Link Router Running at http://localhost:3000"
echo "Tenant Mgmt Api Running at http://localhost:2000"


if [ "$verbose" -eq 1 ]; then
    docker logs -f link-router &
    for i in `seq 1 $target_count`;
    do
        docker logs -f zetta.target.$i &    
    done
    docker logs -f tenant-mgmt-api &
    wait;
fi

while [ "1" -eq "1" ]; do
    sleep 1;
done


