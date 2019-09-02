#/bin/sh


export FABRIC_CFG_PATH=${PWD}

rm -rf $FABRIC_CFG_PATH/crypto-config
rm -rf $FABRIC_CFG_PATH/channel-artifacts
rm $FABRIC_CFG_PATH/configtx.yaml
rm $FABRIC_CFG_PATH/crypto-config.yaml
rm $FABRIC_CFG_PATH/docker-compose.yaml

docker-compose -f docker-compose.yaml down

docker-compose -f docker-compose.yaml kill && docker-compose -f docker-compose.yaml down

# remove the local state
rm -f ~/.hfc-key-store/*

# remove chaincode docker images
docker rm $(docker ps -aq)

