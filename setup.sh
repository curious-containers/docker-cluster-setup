#!/usr/bin/env bash

NUM_NODES=2
NODE_RAM=2048
NODE_CPUS=2
NODE_DISK=20000

echo "--------------------------------------"
echo "DELETE EXISTING NODE"
echo "--------------------------------------"

for i in $(docker-machine ls -q); do
    docker-machine rm ${i}
done

echo "--------------------------------------"
echo "CREATE CLUSTER STORE: cc-consul"
echo "--------------------------------------"

docker-machine create -d virtualbox cc-consul
eval $(docker-machine env cc-consul)
docker run -d -p "8500:8500" -h "consul" progrium/consul -server -bootstrap


for i in $(seq 1 ${NUM_NODES}); do
    echo "--------------------------------------"
    echo "CREATE NODE: cc-node${i}"
    echo "--------------------------------------"

    docker-machine create -d virtualbox \
    --virtualbox-memory ${NODE_RAM} \
    --virtualbox-cpu-count ${NODE_CPUS} \
    --virtualbox-disk-size ${NODE_DISK} \
    --engine-opt="cluster-store=consul://$(docker-machine ip cc-consul):8500" \
    --engine-opt="cluster-advertise=eth1:2376" \
    cc-node${i}

    echo $(docker-machine ip cc-node${i}):2376
done

echo "--------------------------------------"
echo "CREATE NETWORK: cc-overlay-network"
echo "--------------------------------------"

eval $(docker-machine env cc-node1)
network_id=$(docker network create --driver overlay cc-overlay-network)
docker network inspect ${network_id}
