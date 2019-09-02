#/bin/sh

export CRYPTO_CONFIG_DIR=${PWD}/crypto-config
export CHANNEL_ARTIFACT_DIR=${PWD}/channel-artifacts
DOMAIN=$(cat config.json | jq -r '.Domain')

#  check crypto-config directory 
#if [ -d $CRYPTO_CONFIG_DIR ]; then
#    printf "Cannot fine %s\n" $CRYPTO_CONFIG_DIR
#    exit 1
#fi

#  check channel-artifacts directory 
#if [ -d $CHANNEL_ARTIFACT_DIR ]; then
#    printf "Cannot fine %s\n" $CHANNEL_ARTIFACT_DIR
#    exit 1
#fi

function orderingNode () {
    echo    "version: '2'"
    echo 
    echo    "networks:"
    echo    "    basic:"
    echo 
    echo    "services:"
    echo    "    orderer.$DOMAIN:"
    echo    "      container_name: orderer.$DOMAIN"
    echo    "      image: hyperledger/fabric-orderer"
    echo    "      environment:"
    echo    "          - FABRIC_LOGGING_SPEC=info"
    echo    "          #- ORDERER_GENERAL_LOGLEVEL=debug"
    echo    "          - ORDERER_GENERAL_LISTENADDRESS=0.0.0.0"
    echo    "          - ORDERER_GENERAL_GENESISMETHOD=file"
    echo    "          - ORDERER_GENERAL_GENESISFILE=/var/hyperledger/orderer/orderer.genesis.block"
    echo    "          - ORDERER_GENERAL_LOCALMSPID=OrdererMSP"
    echo    "          - ORDERER_GENERAL_LOCALMSPDIR=/var/hyperledger/orderer/msp"
    echo    "          # enabled TLS"
    echo    "          - ORDERER_GENERAL_TLS_ENABLED=true"
    echo    "          - ORDERER_GENERAL_TLS_PRIVATEKEY=/var/hyperledger/orderer/tls/server.key"
    echo    "          - ORDERER_GENERAL_TLS_CERTIFICATE=/var/hyperledger/orderer/tls/server.crt"
    echo    "          - ORDERER_GENERAL_TLS_ROOTCAS=[/var/hyperledger/orderer/tls/ca.crt]"
    echo    "      working_dir: /opt/gopath/src/github.com/hyperledger/fabric"
    echo    "      command: orderer"
    echo    "      volumes:"
    echo    "          - ./channel-artifacts/genesis.block:/var/hyperledger/orderer/orderer.genesis.block"
    echo    "          - ./crypto-config/ordererOrganizations/$DOMAIN/orderers/orderer.$DOMAIN/msp:/var/hyperledger/orderer/msp"
    echo    "          - ./crypto-config/ordererOrganizations/$DOMAIN/orderers/orderer.$DOMAIN/tls:/var/hyperledger/orderer/tls"
    echo    "      ports:"
    echo    "          - 7050:7050"
    echo    "      networks:"
    echo    "          - basic"
}

function peerNode () {
    ORGANIZATIONS=$(cat config.json | jq -r '.Organizations []')
    local default_endport=7051
    local default_port=7053
    local nextpoint=100
    for i in $ORGANIZATIONS
    do 
        PEERS=$(cat config.json | jq -r ".Peers.$i []")
        for q in $PEERS
        do 
            PEERNAME=$q.$DOMAIN
            nextendport=`expr $default_endport + $nextpoint`
            nextport=`expr $default_port + $nextpoint`
            j="$(tr [A-Z] [a-z] <<< "$i")"  # 소문자 변환
            echo 
            echo   "    $PEERNAME:"
            echo   "        container_name: $PEERNAME"
            echo   "        image: hyperledger/fabric-peer"
            echo   "        environment:"
            echo   "            - CORE_VM_ENDPOINT=unix:///host/var/run/docker.sock"
            echo   "            - CORE_PEER_ID=$PEERNAME"
            echo   "            - CORE_PEER_ADDRESS=$PEERNAME:7051"
            echo   "            - CORE_PEER_GOSSIP_EXTERNALENDPOINT=$PEERNAME:$default_endport"
            echo   "            #- CORE_PEER_GOSSIP_BOOTSTRAP=$PEERNAME:7051"
            echo   "            - CORE_PEER_LOCALMSPID=${i}MSP"
            echo   "            - FABRIC_LOGGING_SPEC=info"
            echo   "            - CORE_PEER_TLS_ENABLED=true"
            echo   "            #- CORE_PEER_MSPCONFIGPATH="
            echo   "            - CORE_PEER_GOSSIP_USELEADERELECTION=true"
            echo   "            - CORE_PEER_GOSSIP_ORGLEADER=false"
            echo   "            - CORE_PEER_PROFILE_ENABLED=true"
            echo   "            - CORE_PEER_TLS_CERT_FILE=/etc/hyperledger/fabric/tls/server.crt"
            echo   "            - CORE_PEER_TLS_KEY_FILE=/etc/hyperledger/fabric/tls/server.key"
            echo   "            - CORE_PEER_TLS_ROOTCERT_FILE=/etc/hyperledger/fabric/tls/ca.crt"
            echo   "        working_dir: /opt/gopath/src/github.com/hyperledger/fabric/peer"
            echo   "        command: peer node start"
            echo   "        volumes:"
            echo   "            - /var/run/:/host/var/run/"
            echo   "            - ./crypto-config/peerOrganizations/$j.$DOMAIN/peers/$PEERNAME/msp:/etc/hyperledger/fabric/msp"
            echo   "            - ./crypto-config/peerOrganizations/$j.$DOMAIN/peers/$PEERNAME/tls:/etc/hyperledger/fabric/tls"
            echo   "        ports:"
            echo   "            - $nextendport:$default_endport"     
            echo   "            - $nextport:$default_port"           
            echo   "        depends_on:"
            echo   "            - orderer.$DOMAIN"
            echo   "        networks:"
            echo   "            - basic"
            nextpoint=`expr $nextpoint + 100`          
        done
    done
}


function writedocker () {
    orderingNode
    peerNode
}
writedocker > docker-compose.yaml