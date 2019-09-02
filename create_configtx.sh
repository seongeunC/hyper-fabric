#!/bin/sh

# config.json 파일이 없을 경우 예외처리
CONFIG_NETWORK=$(pwd)"/config.json"


if [ ! -f $CONFIG_NETWORK ]; then
    printf "Cannot fine %s\n" $CONFIG_NETWORK
    exit 1;
fi

DOMAIN=$(cat config.json | jq -r '.Domain')
ORDERER=$(cat config.json | jq -r '.Orderers')

function organization() {
    echo    "Organizations:"
    echo    "    - &OrdererOrg"
    echo    "        Name: OrdererOrg"
    echo    "        ID: OrdererMSP"
    echo    "        MSPDir: crypto-config/ordererOrganizations/$DOMAIN/msp"
    echo    "        Policies:"
    echo    "            Readers:"
    echo    "                Type: Signature"
    echo    "                Rule: "\""OR('OrdererMSP.member')"\"""
    echo    "            Writers:"
    echo    "                Type: Signature"
    echo    "                Rule: "\""OR('OrdererMSP.member')"\"""
    echo    "            Admins:"
    echo    "                Type: Signature"
    echo    "                Rule: "\""OR('OrdererMSP.admin')"\"""
    organization_org
}

function organization_org() {
    ORGANIZATIONS=$(cat config.json | jq -r '.Organizations []')

    # json에 정의된 Peer 가 peer0.org1.org 형식을 지켜야함
    for i in $ORGANIZATIONS
    do 
        j="$(tr [A-Z] [a-z] <<< "$i")"  # 소문자 변환
        echo 
        echo $a
        echo    "    - &$i"
        echo    "        Name: $i""MSP"
        echo    "        ID: $i""MSP"
        echo    "        MSPDir: crypto-config/peerOrganizations/$j.$DOMAIN/msp"
        echo    "        AnchorPeers:"
        PEERS=$(cat config.json | jq -r ".Peers.$i []")
        port=7051
        for q in $PEERS
        do
            num=1
            echo    "            - Host: $q.$DOMAIN"
            echo    "              Port: $port"
            port=`expr $port + $num`
        done
    done
        
}

function orderer() {
    echo 
    echo    "Orderer: &OrdererDefaults"
    echo    "    OrdererType: solo"
    echo    "    Addresses:"
    echo    "        - $ORDERER:7050"
    echo    "    BatchTimeout: 2s"
    echo    "    BatchSize:"
    echo    "        MaxMessageCount: 10"
    echo    "        AbsoluteMaxBytes: 99 MB"
    echo    "        PreferredMaxBytes: 512 KB"
    echo    "    MaxChannels: 0"
    echo    "    Kafka:"
    echo    "        Brokers:"
    echo    "            - 127.0.0.1:9092"
    echo    "    Organizations:"
    echo    "    Policies:"
    echo    "        Readers:"
    echo    "            Type: ImplicitMeta"
    echo    "            Rule: "\""ANY Readers"\"""
    echo    "        Writers:"
    echo    "            Type: ImplicitMeta"
    echo    "            Rule: "\""ANY Writers"\"""
    echo    "        Admins:"
    echo    "            Type: ImplicitMeta"
    echo    "            Rule: "\""MAJORITY Admins"\"""
    echo    "        BlockValidation:"
    echo    "            Type: ImplicitMeta"
    echo    "            Rule: "\""ANY Writers"\"""
}


function application() {
    echo
    echo    "Application: &ApplicationDefaults"
    echo    "    Organizations:"
    echo    "    Policies:"
    echo    "        Readers:"
    echo    "            Type: ImplicitMeta"
    echo    "            Rule: "\""ANY Readers"\"""
    echo    "        Writers:"
    echo    "            Type: ImplicitMeta"
    echo    "            Rule: "\""ANY Writers"\"""
    echo    "        Admins:"
    echo    "            Type: ImplicitMeta"
    echo    "            Rule: "\""MAJORITY Admins"\"""
}

function channel() {
    echo
    echo    "Channel: &ChannelDefaults"
    echo    "    Policies:"
    echo    "        Readers:"
    echo    "            Type: ImplicitMeta"
    echo    "            Rule: "\""ANY Readers"\"""
    echo    "        Writers:"
    echo    "            Type: ImplicitMeta"
    echo    "            Rule: "\""ANY Writers"\"""
    echo    "        Admins:"
    echo    "            Type: ImplicitMeta"
    echo    "            Rule: "\""MAJORITY Admins"\"""
}

function profile () {
    echo
    echo    "Profiles:"
    echo    "    OrdererGenesis:"
    echo    "        Orderer:"
    echo    "            <<: *OrdererDefaults"
    echo    "            Organizations:"
    echo    "                - *OrdererOrg"
    echo    "        Consortiums:"
    echo    "            myConsortium:"
    echo    "                Organizations:"
    for i in $ORGANIZATIONS
    do 
        i=${i//"\""/}   # 따옴표 제거
    echo    "                    - *$i"
    done
    profile_channel
}


function profile_channel () { 
    CHANNELS=$(cat config.json | jq -r '.Channels []')

    for i in $CHANNELS
    do 
        echo 
        echo    "    $i:"
        echo    "        Consortium: myConsortium"
        echo    "        Application:"
        echo    "            <<: *ApplicationDefaults"
        echo    "            Organizations:"
        CHANNELSORG=$(cat config.json | jq -r ".Channelorg.$i []")
        for j in $CHANNELSORG
        do
        echo    "                - *$j"   
        done
    done
} 

function writeConfigtx () {
    organization
    orderer
    application
    channel
    profile
}

writeConfigtx > configtx.yaml