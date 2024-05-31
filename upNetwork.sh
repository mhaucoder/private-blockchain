. registerEnroll.sh
. setEnvVar.sh
# Install path tool
export PATH=${PWD}/bin:$PATH
# Up CA
docker compose -f docker-compose-ca.yaml up -d
sleep 10
# Register and Enroll Orgs
createOrgs
# Up Orgs
docker compose -f docker-compose-catphcm.yaml up -d
sleep 10
docker compose -f docker-compose-pc02.yaml up -d
sleep 10
# Genesis block channel private
CHANNEL_NAME=pc02-private-channel
CHANNEL_PROFILE=PC02PrivateChannelGenesis
configtxgen -profile $CHANNEL_PROFILE -outputBlock ${PWD}/channel/PC02_PRIVATE_CHANNEL/${CHANNEL_NAME}.block -channelID ${CHANNEL_NAME} --configPath ${PWD}/channel/PC02_PRIVATE_CHANNEL
sleep 5
# Join orderer to channel
osnadmin channel join --channelID $CHANNEL_NAME --config-block ${PWD}/channel/PC02_PRIVATE_CHANNEL/${CHANNEL_NAME}.block -o localhost:8053 --ca-file ${PWD}/organizations/memberOrganizations/pc02.gov.vn/tlsca/tlsca.pc02.gov.vn-cert.pem --client-cert ${PWD}/organizations/memberOrganizations/pc02.gov.vn/orderers/pc02-o1.pc02.gov.vn/tls/server.crt --client-key ${PWD}/organizations/memberOrganizations/pc02.gov.vn/orderers/pc02-o1.pc02.gov.vn/tls/server.key
# Join Peer to channel
setOrgPC02
peer channel join -b ${PWD}/channel/PC02_PRIVATE_CHANNEL/${CHANNEL_NAME}.block
# Genesis block channel center
CHANNEL_NAME=center-channel
CHANNEL_PROFILE=CenterChannelGenesis
configtxgen -profile $CHANNEL_PROFILE -outputBlock ${PWD}/channel/CENTER_CHANNEL/${CHANNEL_NAME}.block -channelID ${CHANNEL_NAME} --configPath ${PWD}/channel/CENTER_CHANNEL
sleep 5
# Join orderer to channel
osnadmin channel join --channelID $CHANNEL_NAME --config-block ${PWD}/channel/CENTER_CHANNEL/${CHANNEL_NAME}.block -o localhost:7053 --ca-file ${PWD}/organizations/memberOrganizations/catphcm.gov.vn/tlsca/tlsca.catphcm.gov.vn-cert.pem --client-cert ${PWD}/organizations/memberOrganizations/catphcm.gov.vn/orderers/catphcm-o1.catphcm.gov.vn/tls/server.crt --client-key ${PWD}/organizations/memberOrganizations/catphcm.gov.vn/orderers/catphcm-o1.catphcm.gov.vn/tls/server.key
# Join Peer CATPHCM to channel
setOrgCATPHCM
peer channel join -b ${PWD}/channel/CENTER_CHANNEL/${CHANNEL_NAME}.block
# Join Peer PC02 to channel
setOrgPC02
peer channel join -b ${PWD}/channel/CENTER_CHANNEL/${CHANNEL_NAME}.block

sleep 5