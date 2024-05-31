#!/bin/bash
CC_NAME=$1
CC_SRC_PATH=${PWD}/../../dev_extcc
CCAAS_SERVER_PORT=9999
CC_VERSION="1.0"
export PATH=${PWD}/bin:$PATH
export FABRIC_CFG_PATH=$PWD/organizations/peercfg

#Check chaincode
if [ ! -d $CC_SRC_PATH ]; then
    errorln "Not found folder chaincode dev_extc"
    exit 1
fi

. utils.sh
. registerEnroll.sh
. setEnvVar.sh

packageChaincode() {
  infoln "Package chaincode ..."
  address="${CC_NAME}_ccaas:${CCAAS_SERVER_PORT}"
  prefix=$(basename "$0")
  tempdir=$(mktemp -d -t "$prefix.XXXXXXXX") || error_exit "Error creating temporary directory"
  label=${CC_NAME}_${CC_VERSION}
  mkdir -p "$tempdir/src"
  mkdir -p "${PWD}/chaincode"

cat > "$tempdir/src/connection.json" <<CONN_EOF
{
  "address": "${address}",
  "dial_timeout": "10s",
  "tls_required": false
}
CONN_EOF

   mkdir -p "$tempdir/pkg"

cat << METADATA-EOF > "$tempdir/pkg/metadata.json"
{
    "type": "ccaas",
    "label": "$label"
}
METADATA-EOF

    tar -C "$tempdir/src" -czf "$tempdir/pkg/code.tar.gz" .
    tar -C "$tempdir/pkg" -czf "${PWD}/chaincode/${CC_NAME}.tar.gz" metadata.json code.tar.gz
    rm -Rf "$tempdir"

    PACKAGE_ID=$(peer lifecycle chaincode calculatepackageid ${PWD}/chaincode/${CC_NAME}.tar.gz)
  successln "Packaged chaincode success"
}

buildDockerImages() {
    infoln "Building image chaincode form Dockerfile..."
    set -x
    docker build -f $CC_SRC_PATH/Dockerfile -t ${CC_NAME}_ccaas_image:latest --build-arg CC_SERVER_PORT=9999 $CC_SRC_PATH >&log.txt
    res=$?
    { set +x; } 2>/dev/null
    cat log.txt
    successln "Build image chaincode success, you can check log.txt"
}

startDockerContainer() {
    # start the docker container
    infoln "Start the docker container..."
    set -x
    docker run --rm -d --name ${CC_NAME}_ccaas  \
                  --network cdnv-cahcm \
                  -e CHAINCODE_SERVER_ADDRESS=0.0.0.0:${CCAAS_SERVER_PORT} \
                  -e CHAINCODE_ID=$PACKAGE_ID -e CORE_CHAINCODE_ID_NAME=$PACKAGE_ID \
                    ${CC_NAME}_ccaas_image:latest

    res=$?
    { set +x; } 2>/dev/null
    cat log.txt
    successln "Start the docker container success"
}

# Build the docker image 
buildDockerImages
sleep 5
## package the chaincode
packageChaincode
sleep 5
#Install chanicode on peer CATPHCM
infoln "Install chanicode on peer CATPHCM..."
setOrgCATPHCM
peer lifecycle chaincode install ${PWD}/chaincode/${CC_NAME}.tar.gz

#Install chanicode on peer PC02
infoln "Install chanicode on peer PC02..."
setOrgPC02
peer lifecycle chaincode install ${PWD}/chaincode/${CC_NAME}.tar.gz

#Query chanicode on peer CATPHCM
infoln "Query chanicode on peer CATPHCM"
setOrgCATPHCM
peer lifecycle chaincode queryinstalled --output json | jq -r 'try (.installed_chaincodes[].package_id)' | grep ^${PACKAGE_ID} 

#Query chanicode on peer PC02
infoln "Query chanicode on peer PC02"
setOrgPC02
peer lifecycle chaincode queryinstalled --output json | jq -r 'try (.installed_chaincodes[].package_id)' | grep ^${PACKAGE_ID} 

infoln "Approved and Commit on Channel center-channel"
#Approved chaincode on peer CATPHCM
infoln "Approved chaincode on peer CATPHCM in Channel center-channel"
setOrgCATPHCM
peer lifecycle chaincode approveformyorg -o localhost:7050 --ordererTLSHostnameOverride catphcm-o1.catphcm.gov.vn --tls --cafile ${PWD}/organizations/memberOrganizations/catphcm.gov.vn/tlsca/tlsca.catphcm.gov.vn-cert.pem --channelID center-channel --name ${CC_NAME} --version 1.0 --package-id ${PACKAGE_ID} --sequence 1 --signature-policy "OR('CATPHCM-PMSP.peer')"

#Approved chaincode on peer PC02
infoln "Approved chaincode on peer PC02 in Channel center-channel"
setOrgPC02
peer lifecycle chaincode approveformyorg -o localhost:7050 --ordererTLSHostnameOverride catphcm-o1.catphcm.gov.vn --tls --cafile ${PWD}/organizations/memberOrganizations/catphcm.gov.vn/tlsca/tlsca.catphcm.gov.vn-cert.pem --channelID center-channel --name ${CC_NAME} --version 1.0 --package-id ${PACKAGE_ID} --sequence 1 --signature-policy "OR('CATPHCM-PMSP.peer')"

#Commit chaincode
infoln "Commit chaincode on peer CATPHCM in Channel center-channel"
peer lifecycle chaincode commit -o localhost:7050 --ordererTLSHostnameOverride catphcm-o1.catphcm.gov.vn --channelID center-channel --name ${CC_NAME} --version 1.0 --sequence 1 --signature-policy "OR('CATPHCM-PMSP.peer')" --tls --cafile ${PWD}/organizations/memberOrganizations/catphcm.gov.vn/tlsca/tlsca.catphcm.gov.vn-cert.pem --peerAddresses catphcm-p1.catphcm.gov.vn:7051 --tlsRootCertFiles ${PWD}/organizations/memberOrganizations/catphcm.gov.vn/tlsca/tlsca.catphcm.gov.vn-cert.pem --peerAddresses pc02-p1.pc02.gov.vn:8051 --tlsRootCertFiles ${PWD}/organizations/memberOrganizations/pc02.gov.vn/tlsca/tlsca.pc02.gov.vn-cert.pem
sleep 5
successln "Approved and Commit on Channel center-channel success"

infoln "Approved and Commit on Channel pc02-private-channel"
#Approved chaincode on peer PC02
infoln "Approved chaincode on peer PC02 in Channel pc02-private-channel"
setOrgPC02
peer lifecycle chaincode approveformyorg -o localhost:8050 --ordererTLSHostnameOverride pc02-o1.pc02.gov.vn --tls --cafile ${PWD}/organizations/memberOrganizations/pc02.gov.vn/tlsca/tlsca.pc02.gov.vn-cert.pem --channelID pc02-private-channel --name ${CC_NAME} --version 1.0 --package-id ${PACKAGE_ID} --sequence 1 --signature-policy "OR('PC02-PMSP.peer')"

#Commit chaincode
infoln "Commit chaincode on peer PC02 in Channel pc02-private-channel"
peer lifecycle chaincode commit -o localhost:8050 --ordererTLSHostnameOverride pc02-o1.pc02.gov.vn --channelID pc02-private-channel --name ${CC_NAME} --version 1.0 --sequence 1 --signature-policy "OR('PC02-PMSP.peer')" --tls --cafile ${PWD}/organizations/memberOrganizations/pc02.gov.vn/tlsca/tlsca.pc02.gov.vn-cert.pem --peerAddresses pc02-p1.pc02.gov.vn:8051 --tlsRootCertFiles ${PWD}/organizations/memberOrganizations/pc02.gov.vn/tlsca/tlsca.pc02.gov.vn-cert.pem
successln "Approved and Commit on Channel pc02-private-channel success"

# start the container
infoln "Starting docker container..."
startDockerContainer
sleep 5
## Invoke the chaincode - this does require that the chaincode have the 'initLedger'

#Invoke chaincode
infoln "Invoke chaincode on Channel center-channel"
setOrgCATPHCM
peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride catphcm-o1.catphcm.gov.vn --tls --cafile ${PWD}/organizations/memberOrganizations/catphcm.gov.vn/tlsca/tlsca.catphcm.gov.vn-cert.pem -C center-channel --name ${CC_NAME} -c '{"function":"UserContract:initializeDataDefault","Args":["dev"]}' --peerAddresses catphcm-p1.catphcm.gov.vn:7051 --tlsRootCertFiles ${PWD}/organizations/memberOrganizations/catphcm.gov.vn/tlsca/tlsca.catphcm.gov.vn-cert.pem --peerAddresses pc02-p1.pc02.gov.vn:8051 --tlsRootCertFiles ${PWD}/organizations/memberOrganizations/pc02.gov.vn/tlsca/tlsca.pc02.gov.vn-cert.pem
sleep 3
peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride catphcm-o1.catphcm.gov.vn --tls --cafile ${PWD}/organizations/memberOrganizations/catphcm.gov.vn/tlsca/tlsca.catphcm.gov.vn-cert.pem -C center-channel --name ${CC_NAME} -c '{"function":"RoleContract:initializeDataDefault","Args":["dev"]}' --peerAddresses catphcm-p1.catphcm.gov.vn:7051 --tlsRootCertFiles ${PWD}/organizations/memberOrganizations/catphcm.gov.vn/tlsca/tlsca.catphcm.gov.vn-cert.pem --peerAddresses pc02-p1.pc02.gov.vn:8051 --tlsRootCertFiles ${PWD}/organizations/memberOrganizations/pc02.gov.vn/tlsca/tlsca.pc02.gov.vn-cert.pem
sleep 3
peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride catphcm-o1.catphcm.gov.vn --tls --cafile ${PWD}/organizations/memberOrganizations/catphcm.gov.vn/tlsca/tlsca.catphcm.gov.vn-cert.pem -C center-channel --name ${CC_NAME} -c '{"function":"OrganizationContract:initializeDataDefault","Args":["dev"]}'  --peerAddresses catphcm-p1.catphcm.gov.vn:7051 --tlsRootCertFiles ${PWD}/organizations/memberOrganizations/catphcm.gov.vn/tlsca/tlsca.catphcm.gov.vn-cert.pem --peerAddresses pc02-p1.pc02.gov.vn:8051 --tlsRootCertFiles ${PWD}/organizations/memberOrganizations/pc02.gov.vn/tlsca/tlsca.pc02.gov.vn-cert.pem
sleep 3
peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride catphcm-o1.catphcm.gov.vn --tls --cafile ${PWD}/organizations/memberOrganizations/catphcm.gov.vn/tlsca/tlsca.catphcm.gov.vn-cert.pem -C center-channel --name ${CC_NAME} -c '{"function":"PermissionContract:initializeDataDefault","Args":["dev"]}'
sleep 3
successln "Invoke chaincode on Channel center-channel success"

#Invoke chaincode
infoln "Invoke chaincode on Channel pc02-private-channel"
setOrgPC02
peer chaincode invoke -o localhost:8050 --ordererTLSHostnameOverride pc02-o1.pc02.gov.vn --tls --cafile ${PWD}/organizations/memberOrganizations/pc02.gov.vn/tlsca/tlsca.pc02.gov.vn-cert.pem -C pc02-private-channel -n ${CC_NAME} -c '{"function":"UserContract:initializeDataDefault","Args":["dev"]}'
sleep 3
peer chaincode invoke -o localhost:8050 --ordererTLSHostnameOverride pc02-o1.pc02.gov.vn --tls --cafile ${PWD}/organizations/memberOrganizations/pc02.gov.vn/tlsca/tlsca.pc02.gov.vn-cert.pem -C pc02-private-channel -n ${CC_NAME} -c '{"function":"RoleContract:initializeDataDefault","Args":["dev"]}'
sleep 3
peer chaincode invoke -o localhost:8050 --ordererTLSHostnameOverride pc02-o1.pc02.gov.vn --tls --cafile ${PWD}/organizations/memberOrganizations/pc02.gov.vn/tlsca/tlsca.pc02.gov.vn-cert.pem -C pc02-private-channel -n ${CC_NAME} -c '{"function":"OrganizationContract:initializeDataDefault","Args":["dev"]}'
sleep 3
peer chaincode invoke -o localhost:8050 --ordererTLSHostnameOverride pc02-o1.pc02.gov.vn --tls --cafile ${PWD}/organizations/memberOrganizations/pc02.gov.vn/tlsca/tlsca.pc02.gov.vn-cert.pem -C pc02-private-channel -n ${CC_NAME} -c '{"function":"PermissionContract:initializeDataDefault","Args":["dev"]}'
sleep 3
successln "Invoke chaincode on Channel pc02-private-channel success"
