#!/bin/bash

# Include necessary scripts
. scripts/registerEnroll.sh
. scripts/setEnvVar.sh
. scripts/utils.sh

# Install path tool
infoln "Setting PATH..."
export PATH=${PWD}/bin:$PATH

# Up CA
infoln "Starting CA containers..."
docker compose -f docker/docker-compose-ca.yaml up -d 
sleep 10

# Register and Enroll Orgs
infoln "Registering and enrolling organizations..."
createOrgs

# Up Orgs
infoln "Starting organization containers..."
for compose_file in docker/docker-compose-catphcm.yaml docker/docker-compose-pc02.yaml; do
    infoln "Starting container for $compose_file..."
    docker compose -f $compose_file up -d
    sleep 10
done

# Genesis block channel private
CHANNEL_NAME=pc02-private-channel
CHANNEL_PROFILE=PC02PrivateChannelGenesis
BLOCK_PATH=${PWD}/channel/PC02_PRIVATE_CHANNEL/${CHANNEL_NAME}.block
CONFIG_PATH=${PWD}/channel/PC02_PRIVATE_CHANNEL

infoln "Generating genesis block for $CHANNEL_NAME..."
configtxgen -profile $CHANNEL_PROFILE -outputBlock $BLOCK_PATH -channelID $CHANNEL_NAME --configPath $CONFIG_PATH 
sleep 5
checkFile $BLOCK_PATH
if [ $? -ne 0 ]; then
    errorln "Failed to generate genesis block for $CHANNEL_NAME."
    exit 1
fi

# Join orderer to channel
infoln "Joining orderer to $CHANNEL_NAME..."
osnadmin channel join --channelID $CHANNEL_NAME --config-block $BLOCK_PATH -o localhost:8053 \
    --ca-file ${PWD}/organizations/memberOrganizations/pc02.gov.vn/tlsca/tlsca.pc02.gov.vn-cert.pem \
    --client-cert ${PWD}/organizations/memberOrganizations/pc02.gov.vn/orderers/pc02-o1.pc02.gov.vn/tls/server.crt \
    --client-key ${PWD}/organizations/memberOrganizations/pc02.gov.vn/orderers/pc02-o1.pc02.gov.vn/tls/server.key 
sleep 5

# Join Peer to channel
infoln "Joining peer PC02 to $CHANNEL_NAME..."
setOrgPC02
peer channel join -b $BLOCK_PATH 
if [ $? -ne 0 ]; then
    errorln "Failed to join peer PC02 to $CHANNEL_NAME."
    exit 1
fi

# Genesis block channel center
CHANNEL_NAME=center-channel
CHANNEL_PROFILE=CenterChannelGenesis
BLOCK_PATH=${PWD}/channel/CENTER_CHANNEL/${CHANNEL_NAME}.block
CONFIG_PATH=${PWD}/channel/CENTER_CHANNEL

infoln "Generating genesis block for $CHANNEL_NAME..."
configtxgen -profile $CHANNEL_PROFILE -outputBlock $BLOCK_PATH -channelID $CHANNEL_NAME --configPath $CONFIG_PATH  
sleep 5
checkFile $BLOCK_PATH
if [ $? -ne 0 ]; then
    errorln "Failed to generate genesis block for $CHANNEL_NAME."
    exit 1
fi

# Join orderer to channel
infoln "Joining orderer to $CHANNEL_NAME..."
osnadmin channel join --channelID $CHANNEL_NAME --config-block $BLOCK_PATH -o localhost:7053 \
    --ca-file ${PWD}/organizations/memberOrganizations/catphcm.gov.vn/tlsca/tlsca.catphcm.gov.vn-cert.pem \
    --client-cert ${PWD}/organizations/memberOrganizations/catphcm.gov.vn/orderers/catphcm-o1.catphcm.gov.vn/tls/server.crt \
    --client-key ${PWD}/organizations/memberOrganizations/catphcm.gov.vn/orderers/catphcm-o1.catphcm.gov.vn/tls/server.key  
sleep 5

# Join Peer CATPHCM to channel
infoln "Joining peer CATPHCM to $CHANNEL_NAME..."
setOrgCATPHCM
peer channel join -b $BLOCK_PATH  
if [ $? -ne 0 ]; then
    errorln "Failed to join peer CATPHCM to $CHANNEL_NAME."
    exit 1
fi

# Join Peer PC02 to channel
infoln "Joining peer PC02 to $CHANNEL_NAME..."
setOrgPC02
peer channel join -b $BLOCK_PATH  
if [ $? -ne 0 ]; then
    errorln "Failed to join peer PC02 to $CHANNEL_NAME."
    exit 1
fi

function loadCertEnv(){
    checkFolder $PATH_ORG
    PATH_MSP=$(find "$PATH_ORG/users" -name '*-u1@*' -type d -prune -print | head -n 1)/msp
    FABRIC_MSP_ID=$1
    FABRIC_PEER_HOST_ALIAS=$2
    FABRIC_PEER_ENDPOINT_PORT=$3
    CERT_CONTENT=$(cat "$(ls -1 $PATH_MSP/signcerts/*.pem | head -n 1)")
    PRIVATE_KEY_CONTENT=$(cat "$(ls -1 $PATH_MSP/keystore/* | head -n 1)")
    TLS_CA_CERT_CONTENT=$(cat "$(ls -1 $PATH_MSP/cacerts/*.pem | head -n 1)")
    IP_ADDRESS=$(hostname -I | awk '{print $1}')
    {
      echo "FABRIC_MSP_ID = $FABRIC_MSP_ID"
      echo "FABRIC_PEER_HOST_ALIAS = $FABRIC_PEER_HOST_ALIAS"
      echo "FABRIC_TLS_CA_CERTIFICATE = '$TLS_CA_CERT_CONTENT'"
      echo "FABRIC_PEER_ENDPOINT = $IP_ADDRESS:$FABRIC_PEER_ENDPOINT_PORT"
      echo "FABRIC_CLIENT_CERTIFICATE = '$CERT_CONTENT'"
      echo "FABRIC_CLIENT_PRIVATE_KEY = '$PRIVATE_KEY_CONTENT'"
    } > $PATH_ORG/fabric.gateway.env

    warnln "Copy the following content into the API's environment"
    cat $PATH_ORG/fabric.gateway.env
}

PATH_ORG=${PWD}/organizations/memberOrganizations/catphcm.gov.vn
loadCertEnv "CATPHCM-PMSP" "catphcm-p1.catphcm.gov.vn" 7051

PATH_ORG=${PWD}/organizations/memberOrganizations/pc02.gov.vn
loadCertEnv "PC02-PMSP" "pc02-p1.pc02.gov.vn" 8051

successln "Script execution completed successfully."