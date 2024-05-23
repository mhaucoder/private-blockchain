. registerEnroll.sh
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
export CORE_PEER_TLS_ENABLED=true
export FABRIC_CFG_PATH=$PWD/organizations/peercfg
export CORE_PEER_LOCALMSPID="PC02-PMSP"
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/memberOrganizations/pc02.gov.vn/users/pc02-a1@pc02.gov.vn/msp
export CORE_PEER_ADDRESS=localhost:8051
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/memberOrganizations/pc02.gov.vn/tlsca/tlsca.pc02.gov.vn-cert.pem
peer channel join -b ${PWD}/channel/PC02_PRIVATE_CHANNEL/${CHANNEL_NAME}.block
# Genesis block channel center
CHANNEL_NAME=center-channel
CHANNEL_PROFILE=CenterChannelGenesis
configtxgen -profile $CHANNEL_PROFILE -outputBlock ${PWD}/channel/CENTER_CHANNEL/${CHANNEL_NAME}.block -channelID ${CHANNEL_NAME} --configPath ${PWD}/channel/CENTER_CHANNEL
sleep 5
# Join orderer to channel
osnadmin channel join --channelID $CHANNEL_NAME --config-block ${PWD}/channel/CENTER_CHANNEL/${CHANNEL_NAME}.block -o localhost:7053 --ca-file ${PWD}/organizations/memberOrganizations/catphcm.gov.vn/tlsca/tlsca.catphcm.gov.vn-cert.pem --client-cert ${PWD}/organizations/memberOrganizations/catphcm.gov.vn/orderers/catphcm-o1.catphcm.gov.vn/tls/server.crt --client-key ${PWD}/organizations/memberOrganizations/catphcm.gov.vn/orderers/catphcm-o1.catphcm.gov.vn/tls/server.key
# Join Peer CATPHCM to channel
export CORE_PEER_TLS_ENABLED=true
export FABRIC_CFG_PATH=$PWD/organizations/peercfg
export CORE_PEER_LOCALMSPID="CATPHCM-PMSP"
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/memberOrganizations/catphcm.gov.vn/users/catphcm-a1@catphcm.gov.vn/msp
export CORE_PEER_ADDRESS=localhost:7051
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/memberOrganizations/catphcm.gov.vn/tlsca/tlsca.catphcm.gov.vn-cert.pem
peer channel join -b ${PWD}/channel/CENTER_CHANNEL/${CHANNEL_NAME}.block
# Join Peer PC02 to channel
export CORE_PEER_TLS_ENABLED=true
export FABRIC_CFG_PATH=$PWD/organizations/peercfg
export CORE_PEER_LOCALMSPID="PC02-PMSP"
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/memberOrganizations/pc02.gov.vn/users/pc02-a1@pc02.gov.vn/msp
export CORE_PEER_ADDRESS=localhost:8051
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/memberOrganizations/pc02.gov.vn/tlsca/tlsca.pc02.gov.vn-cert.pem
peer channel join -b ${PWD}/channel/CENTER_CHANNEL/${CHANNEL_NAME}.block

#Package chaincode
peer lifecycle chaincode package ${PWD}/chaincode/chaincode_v1.tar.gz --path ${PWD}/../dev_extcc --lang node --label chaincode_v1_1.0
sleep 3
PACKAGE_ID=$(peer lifecycle chaincode calculatepackageid ${PWD}/chaincode/chaincode_v1.tar.gz)

#Install chanicode on peer CATPHCM
export CORE_PEER_TLS_ENABLED=true
export FABRIC_CFG_PATH=$PWD/organizations/peercfg
export CORE_PEER_LOCALMSPID="CATPHCM-PMSP"
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/memberOrganizations/catphcm.gov.vn/users/catphcm-a1@catphcm.gov.vn/msp
export CORE_PEER_ADDRESS=localhost:7051
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/memberOrganizations/catphcm.gov.vn/tlsca/tlsca.catphcm.gov.vn-cert.pem
peer lifecycle chaincode install ${PWD}/chaincode/chaincode_v1.tar.gz

#Install chanicode on peer PC02
export CORE_PEER_TLS_ENABLED=true
export FABRIC_CFG_PATH=$PWD/organizations/peercfg
export CORE_PEER_LOCALMSPID="PC02-PMSP"
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/memberOrganizations/pc02.gov.vn/users/pc02-a1@pc02.gov.vn/msp
export CORE_PEER_ADDRESS=localhost:8051
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/memberOrganizations/pc02.gov.vn/tlsca/tlsca.pc02.gov.vn-cert.pem
peer lifecycle chaincode install ${PWD}/chaincode/chaincode_v1.tar.gz

#Query chanicode on peer CATPHCM
export CORE_PEER_TLS_ENABLED=true
export FABRIC_CFG_PATH=$PWD/organizations/peercfg
export CORE_PEER_LOCALMSPID="CATPHCM-PMSP"
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/memberOrganizations/catphcm.gov.vn/users/catphcm-a1@catphcm.gov.vn/msp
export CORE_PEER_ADDRESS=localhost:7051
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/memberOrganizations/catphcm.gov.vn/tlsca/tlsca.catphcm.gov.vn-cert.pem
peer lifecycle chaincode queryinstalled --output json | jq -r 'try (.installed_chaincodes[].package_id)' | grep ^${PACKAGE_ID} 

#Approved chaincode on peer CATPHCM
export CORE_PEER_TLS_ENABLED=true
export FABRIC_CFG_PATH=$PWD/organizations/peercfg
export CORE_PEER_LOCALMSPID="CATPHCM-PMSP"
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/memberOrganizations/catphcm.gov.vn/users/catphcm-a1@catphcm.gov.vn/msp
export CORE_PEER_ADDRESS=localhost:7051
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/memberOrganizations/catphcm.gov.vn/tlsca/tlsca.catphcm.gov.vn-cert.pem
peer lifecycle chaincode approveformyorg -o localhost:7050 --ordererTLSHostnameOverride catphcm-o1.catphcm.gov.vn --tls --cafile ${PWD}/organizations/memberOrganizations/catphcm.gov.vn/tlsca/tlsca.catphcm.gov.vn-cert.pem --channelID center-channel --name chaincode_v1 --version 1.0 --package-id ${PACKAGE_ID}  --sequence 1 --signature-policy "OR('CATPHCM-PMSP.peer','PC02-PMSP.peer')"

#Approved chaincode on peer PC02
export CORE_PEER_TLS_ENABLED=true
export FABRIC_CFG_PATH=$PWD/organizations/peercfg
export CORE_PEER_LOCALMSPID="PC02-PMSP"
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/memberOrganizations/pc02.gov.vn/users/pc02-a1@pc02.gov.vn/msp
export CORE_PEER_ADDRESS=localhost:8051
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/memberOrganizations/pc02.gov.vn/tlsca/tlsca.pc02.gov.vn-cert.pem
peer lifecycle chaincode approveformyorg -o localhost:7050 --ordererTLSHostnameOverride catphcm-o1.catphcm.gov.vn --tls --cafile ${PWD}/organizations/memberOrganizations/catphcm.gov.vn/tlsca/tlsca.catphcm.gov.vn-cert.pem --channelID center-channel --name chaincode_v1 --version 1.0 --package-id ${PACKAGE_ID} --sequence 1 --signature-policy "OR('CATPHCM-PMSP.peer','PC02-PMSP.peer')"

#Commit chaincode
export CORE_PEER_TLS_ENABLED=true
export FABRIC_CFG_PATH=$PWD/organizations/peercfg
export CORE_PEER_LOCALMSPID="CATPHCM-PMSP"
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/memberOrganizations/catphcm.gov.vn/users/catphcm-a1@catphcm.gov.vn/msp
export CORE_PEER_ADDRESS=localhost:7051
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/memberOrganizations/catphcm.gov.vn/tlsca/tlsca.catphcm.gov.vn-cert.pem
peer lifecycle chaincode commit -o localhost:7050 --ordererTLSHostnameOverride catphcm-o1.catphcm.gov.vn --channelID center-channel --name chaincode_v1 --version 1.0 --sequence 1 --signature-policy "OR('CATPHCM-PMSP.peer','PC02-PMSP.peer')" --tls --cafile ${PWD}/organizations/memberOrganizations/catphcm.gov.vn/tlsca/tlsca.catphcm.gov.vn-cert.pem --peerAddresses catphcm-p1.catphcm.gov.vn:7051 --tlsRootCertFiles ${PWD}/organizations/memberOrganizations/catphcm.gov.vn/tlsca/tlsca.catphcm.gov.vn-cert.pem --peerAddresses pc02-p1.pc02.gov.vn:8051 --tlsRootCertFiles ${PWD}/organizations/memberOrganizations/pc02.gov.vn/tlsca/tlsca.pc02.gov.vn-cert.pem

#Invoke chaincode
export CORE_PEER_TLS_ENABLED=true
export FABRIC_CFG_PATH=$PWD/organizations/peercfg
export CORE_PEER_LOCALMSPID="CATPHCM-PMSP"
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/memberOrganizations/catphcm.gov.vn/users/catphcm-a1@catphcm.gov.vn/msp
export CORE_PEER_ADDRESS=localhost:7051
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/memberOrganizations/catphcm.gov.vn/tlsca/tlsca.catphcm.gov.vn-cert.pem
peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride catphcm-o1.catphcm.gov.vn --tls --cafile ${PWD}/organizations/memberOrganizations/catphcm.gov.vn/tlsca/tlsca.catphcm.gov.vn-cert.pem -C center-channel --name chaincode_v1 -c '{"function":"UserContract:initializeDataDefault","Args":["dev"]}' --peerAddresses catphcm-p1.catphcm.gov.vn:7051 --tlsRootCertFiles ${PWD}/organizations/memberOrganizations/catphcm.gov.vn/tlsca/tlsca.catphcm.gov.vn-cert.pem --peerAddresses pc02-p1.pc02.gov.vn:8051 --tlsRootCertFiles ${PWD}/organizations/memberOrganizations/pc02.gov.vn/tlsca/tlsca.pc02.gov.vn-cert.pem
sleep 1
peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride catphcm-o1.catphcm.gov.vn --tls --cafile ${PWD}/organizations/memberOrganizations/catphcm.gov.vn/tlsca/tlsca.catphcm.gov.vn-cert.pem -C center-channel --name chaincode_v1 -c '{"function":"RoleContract:initializeDataDefault","Args":["dev"]}' --peerAddresses catphcm-p1.catphcm.gov.vn:7051 --tlsRootCertFiles ${PWD}/organizations/memberOrganizations/catphcm.gov.vn/tlsca/tlsca.catphcm.gov.vn-cert.pem --peerAddresses pc02-p1.pc02.gov.vn:8051 --tlsRootCertFiles ${PWD}/organizations/memberOrganizations/pc02.gov.vn/tlsca/tlsca.pc02.gov.vn-cert.pem
sleep 1
peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride catphcm-o1.catphcm.gov.vn --tls --cafile ${PWD}/organizations/memberOrganizations/catphcm.gov.vn/tlsca/tlsca.catphcm.gov.vn-cert.pem -C center-channel --name chaincode_v1 -c '{"function":"OrganizationContract:initializeDataDefault","Args":["dev"]}'  --peerAddresses catphcm-p1.catphcm.gov.vn:7051 --tlsRootCertFiles ${PWD}/organizations/memberOrganizations/catphcm.gov.vn/tlsca/tlsca.catphcm.gov.vn-cert.pem --peerAddresses pc02-p1.pc02.gov.vn:8051 --tlsRootCertFiles ${PWD}/organizations/memberOrganizations/pc02.gov.vn/tlsca/tlsca.pc02.gov.vn-cert.pem
sleep 1
peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride catphcm-o1.catphcm.gov.vn --tls --cafile ${PWD}/organizations/memberOrganizations/catphcm.gov.vn/tlsca/tlsca.catphcm.gov.vn-cert.pem -C center-channel --name chaincode_v1 -c '{"function":"PermissionContract:initializeDataDefault","Args":["dev"]}'


#Package chaincode in channel private
peer lifecycle chaincode package ${PWD}/chaincode/chaincode_private_v1.tar.gz --path ${PWD}/../dev_extcc --lang node --label chaincode_private_v1_1.0
sleep 3
PACKAGE_ID=$(peer lifecycle chaincode calculatepackageid ${PWD}/chaincode/chaincode_private_v1.tar.gz)

#Install chanicode on peer PC02
export CORE_PEER_TLS_ENABLED=true
export FABRIC_CFG_PATH=$PWD/organizations/peercfg
export CORE_PEER_LOCALMSPID="PC02-PMSP"
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/memberOrganizations/pc02.gov.vn/users/pc02-a1@pc02.gov.vn/msp
export CORE_PEER_ADDRESS=localhost:8051
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/memberOrganizations/pc02.gov.vn/tlsca/tlsca.pc02.gov.vn-cert.pem
peer lifecycle chaincode install ${PWD}/chaincode/chaincode_private_v1.tar.gz

#Query chanicode on peer PC02
export CORE_PEER_TLS_ENABLED=true
export FABRIC_CFG_PATH=$PWD/organizations/peercfg
export CORE_PEER_LOCALMSPID="PC02-PMSP"
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/memberOrganizations/pc02.gov.vn/users/pc02-a1@pc02.gov.vn/msp
export CORE_PEER_ADDRESS=localhost:8051
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/memberOrganizations/pc02.gov.vn/tlsca/tlsca.pc02.gov.vn-cert.pem
peer lifecycle chaincode queryinstalled --output json | jq -r 'try (.installed_chaincodes[].package_id)' | grep ^${PACKAGE_ID} 

#Approved chaincode on peer PC02
export CORE_PEER_TLS_ENABLED=true
export FABRIC_CFG_PATH=$PWD/organizations/peercfg
export CORE_PEER_LOCALMSPID="PC02-PMSP"
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/memberOrganizations/pc02.gov.vn/users/pc02-a1@pc02.gov.vn/msp
export CORE_PEER_ADDRESS=localhost:8051
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/memberOrganizations/pc02.gov.vn/tlsca/tlsca.pc02.gov.vn-cert.pem
peer lifecycle chaincode approveformyorg -o localhost:8050 --ordererTLSHostnameOverride pc02-o1.pc02.gov.vn --tls --cafile ${PWD}/organizations/memberOrganizations/pc02.gov.vn/tlsca/tlsca.pc02.gov.vn-cert.pem --channelID pc02-private-channel --name chaincode_private_v1 --version 1.0 --package-id ${PACKAGE_ID} --sequence 1 --signature-policy "OR('PC02-PMSP.peer')"

#Commit chaincode
export CORE_PEER_TLS_ENABLED=true
export FABRIC_CFG_PATH=$PWD/organizations/peercfg
export CORE_PEER_LOCALMSPID="PC02-PMSP"
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/memberOrganizations/pc02.gov.vn/users/pc02-a1@pc02.gov.vn/msp
export CORE_PEER_ADDRESS=localhost:8051
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/memberOrganizations/pc02.gov.vn/tlsca/tlsca.pc02.gov.vn-cert.pem
peer lifecycle chaincode commit -o localhost:8050 --ordererTLSHostnameOverride pc02-o1.pc02.gov.vn --channelID pc02-private-channel --name chaincode_private_v1 --version 1.0 --sequence 1 --signature-policy "OR('PC02-PMSP.peer')" --tls --cafile ${PWD}/organizations/memberOrganizations/pc02.gov.vn/tlsca/tlsca.pc02.gov.vn-cert.pem --peerAddresses pc02-p1.pc02.gov.vn:8051 --tlsRootCertFiles ${PWD}/organizations/memberOrganizations/pc02.gov.vn/tlsca/tlsca.pc02.gov.vn-cert.pem

#Invoke chaincode
export CORE_PEER_TLS_ENABLED=true
export FABRIC_CFG_PATH=$PWD/organizations/peercfg
export CORE_PEER_LOCALMSPID="PC02-PMSP"
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/memberOrganizations/pc02.gov.vn/users/pc02-a1@pc02.gov.vn/msp
export CORE_PEER_ADDRESS=localhost:8051
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/memberOrganizations/pc02.gov.vn/tlsca/tlsca.pc02.gov.vn-cert.pem
peer chaincode invoke -o localhost:8050 --ordererTLSHostnameOverride pc02-o1.pc02.gov.vn --tls --cafile ${PWD}/organizations/memberOrganizations/pc02.gov.vn/tlsca/tlsca.pc02.gov.vn-cert.pem -C pc02-private-channel -n chaincode_private_v1 -c '{"function":"UserContract:initializeDataDefault","Args":["dev"]}'
sleep 1
peer chaincode invoke -o localhost:8050 --ordererTLSHostnameOverride pc02-o1.pc02.gov.vn --tls --cafile ${PWD}/organizations/memberOrganizations/pc02.gov.vn/tlsca/tlsca.pc02.gov.vn-cert.pem -C pc02-private-channel -n chaincode_private_v1 -c '{"function":"RoleContract:initializeDataDefault","Args":["dev"]}'
sleep 1
peer chaincode invoke -o localhost:8050 --ordererTLSHostnameOverride pc02-o1.pc02.gov.vn --tls --cafile ${PWD}/organizations/memberOrganizations/pc02.gov.vn/tlsca/tlsca.pc02.gov.vn-cert.pem -C pc02-private-channel -n chaincode_private_v1 -c '{"function":"OrganizationContract:initializeDataDefault","Args":["dev"]}'
sleep 1
peer chaincode invoke -o localhost:8050 --ordererTLSHostnameOverride pc02-o1.pc02.gov.vn --tls --cafile ${PWD}/organizations/memberOrganizations/pc02.gov.vn/tlsca/tlsca.pc02.gov.vn-cert.pem -C pc02-private-channel -n chaincode_private_v1 -c '{"function":"PermissionContract:initializeDataDefault","Args":["dev"]}'