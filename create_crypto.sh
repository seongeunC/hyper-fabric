#!/bin/sh

# config.json 파일이 없을 경우 예외처리
CONFIG_NETWORK=$(pwd)"/config.json"
ORDERER=$(cat config.json | jq -r '.Orderers')
DOMAIN=$(cat config.json | jq -r '.Domain')

if [ ! -f $CONFIG_NETWORK ]; then
    printf "Cannot fine %s\n" $CONFIG_NETWORK
    exit 1;
fi

function ordererOrgs() {
    DOMAIN=$(cat config.json | jq -r '.Domain')
    echo 
    echo    "OrdererOrgs:"
    echo    "  - Name: Orderer"
    echo    "    Domain: "$DOMAIN
    echo    "    Specs:"
    echo    "      - Hostname: $ORDERER"
    echo    "PeerOrgs:"
}

function peerOrg () {
    ORGANIZATIONS=$(cat config.json | jq -r '.Organizations []')

    for i in $ORGANIZATIONS
    do 
        j="$(tr [A-Z] [a-z] <<< "$i")"  # 소문자 변환
        echo 
        echo    "  - Name: $i"
        echo    "    Domain: $j.$DOMAIN"
        echo    "    Template:"
        echo    "      Count: 1"
        echo    "    Users:"
        echo    "      Count: 1"
    done
}

function wrtiecrypto () {
    ordererOrgs
    peerOrg
}

wrtiecrypto > crypto-config.yaml