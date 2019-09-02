#!/bin/sh

export PATH=${PWD}/bin:$PATH
export FABRIC_CFG_PATH=${PWD}
export FABRIC_CRYPTO_CONFIG=${PWD}/crypto-config.yaml
export FABRIC_CONFIGTX=${PWD}/configtx.yaml


# remove previous crypto material and config transactions and create channel-artifacts/folder
rm -rf $FABRIC_CFG_PATH/channel-artifacts/*
rm -rf $FABRIC_CFG_PATH/crypto-config/*
mkdir $FABRIC_CFG_PATH/channel-artifacts

# check file 'crypto-config.yaml'
if [ ! -f $FABRIC_CRYPTO_CONFIG ]; then
    printf "Cannot fine %s\n" $FABRIC_CRYPTO_CONFIG
    printf "Execute $FABRIC_CFG_PATH/create_crypto.sh\n"
    exit 1;
fi

# check file 'configtx.yaml'
if [ ! -f $FABRIC_CONFIGTX ]; then
    printf "Cannot fine %s\n" $FABRIC_CONFIGTX
    printf "Execute $FABRIC_CFG_PATH/create_configtx.sh\n"
    exit 1;
fi

# generate crypto material
cryptogen generate --config=./crypto-config.yaml
if [ "$?" -ne 0 ]; then
  echo "Failed to generate crypto material..." 
  exit 1
fi



# generate genesis block for orderer
configtxgen -profile OrdererGenesis -outputBlock ./channel-artifacts/genesis.block
if [ "$?" -ne 0 ]; then
    echo "Failed to generate orderer genesis block..."
    exit 1
fi

# generate channel configuration transaction
CHANNELS=$(cat config.json | jq -r '.Channels []')
for i in $CHANNELS
do 
    configtxgen -profile $i -outputCreateChannelTx ./channel-artifacts/$i.tx -channelID $i
    if [ "$?" -ne 0 ]; then
    echo "Failed to generate "$i" channel configuration transaction..."
    exit 1
    fi
done

# generate anchor peer transaction
#앵커피어는 조직 간의 피어들에 대한 정보 교환의 대리인으로 사용된다. 
#이로써 서로에 대한 위치를 알게 되어 Peer 하나에서 체인코드를 시작하면 모두에 적용될 수 있게 되며
#MSP에 대한 공유도 가능해진다.적어도 하나의 앵키피어가 채널 설정시 정의되야하며, 
#채널에 참여하는 피어들은 제네시스 블록안에 기록된 앵커피어에 대한 정보를 공유하게 된다. 
for i in $CHANNELS
do 
    CHANNELSORG=$(cat config.json | jq -r ".Channelorg.$i []")
    for j in $CHANNELSORG
    do
        configtxgen -profile $i -outputAnchorPeersUpdate ./channel-artifacts/${j}MSP_${i}anchors.tx -channelID $i -asOrg ${j}MSP
        if [ "$?" -ne 0 ]; then
            echo "Failed to generate anchor peer update for $j in $i..."
        fi
    done
done
