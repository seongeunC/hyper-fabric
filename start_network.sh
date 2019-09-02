#/bin/sh

docker-compose -f docker-compose.yaml down

export FABRIC_CFG_PATH=${PWD}
DOCKER_COMPOSE=$FABRIC_CFG_PATH/docker-compose.yaml

cd $FABRIC_CFG_PATH

if [ ! -f $DOCKER_COMPOSE ]; then
    printf "Cannot fine %s\n" $DOCKER_COMPOSE
    exit 1;
fi

docker-compose -f $DOCKER_COMPOSE up orderer.org peer0.org1.org peer0.org2.org