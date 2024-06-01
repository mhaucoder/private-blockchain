#!/bin/bash

# Variables
CC_NAME=$1
CC_SRC_PATH="${PWD}/../../dev_extcc"
CCAAS_SERVER_PORT=9999
CC_VERSION="1.0"
export PATH=${PWD}/bin:$PATH
export FABRIC_CFG_PATH=$PWD/organizations/peercfg

# Check if chaincode directory exists
if [ ! -d "$CC_SRC_PATH" ]; then
    errorln "ERROR: Chaincode directory dev_extcc not found"
    exit 1
fi

# Include necessary scripts
. scripts/utils.sh
. scripts/registerEnroll.sh
. scripts/setEnvVar.sh

packageChaincode() {
    infoln "INFO: Packaging chaincode..."
    local address="${CC_NAME}_ccaas:${CCAAS_SERVER_PORT}"
    local tempdir=$(mktemp -d)
    local label="${CC_NAME}_${CC_VERSION}"
    
    mkdir -p "$tempdir/src" "$tempdir/pkg" "${PWD}/chaincode"

    cat > "$tempdir/src/connection.json" <<CONN_EOF
{
  "address": "${address}",
  "dial_timeout": "10s",
  "tls_required": false
}
CONN_EOF

    cat > "$tempdir/pkg/metadata.json" <<METADATA-EOF
{
    "type": "ccaas",
    "label": "$label"
}
METADATA-EOF

    tar -C "$tempdir/src" -czf "$tempdir/pkg/code.tar.gz" .
    tar -C "$tempdir/pkg" -czf "${PWD}/chaincode/${CC_NAME}.tar.gz" metadata.json code.tar.gz
    rm -Rf "$tempdir"

    PACKAGE_ID=$(peer lifecycle chaincode calculatepackageid ${PWD}/chaincode/${CC_NAME}.tar.gz)
    successln "INFO: Chaincode packaged successfully"
}

buildDockerImages() {
    infoln "INFO: Building Docker image for chaincode..."
    docker build -f "$CC_SRC_PATH/Dockerfile" -t "${CC_NAME}_ccaas_image:latest" --build-arg CC_SERVER_PORT=$CCAAS_SERVER_PORT "$CC_SRC_PATH" >&log.txt
    if [ $? -ne 0 ]; then
        errorln "ERROR: Failed to build Docker image"
        exit 1
    fi
    cat log.txt
    successln "INFO: Docker image built successfully, check log.txt for details"
}

startDockerContainer() {
    infoln "INFO: Starting Docker container for chaincode..."
    docker run --rm -d --name "${CC_NAME}_ccaas" \
        --network cdnv-cahcm \
        -e CHAINCODE_SERVER_ADDRESS="0.0.0.0:${CCAAS_SERVER_PORT}" \
        -e CHAINCODE_ID=$PACKAGE_ID \
        -e CORE_CHAINCODE_ID_NAME=$PACKAGE_ID \
        "${CC_NAME}_ccaas_image:latest"
    
    if [ $? -ne 0 ]; then
        errorln "ERROR: Failed to start Docker container"
        exit 1
    fi
    successln "INFO: Docker container started successfully"
}

# Main script execution
buildDockerImages
sleep 5
packageChaincode
sleep 5

# Install chaincode on peers
infoln "INFO: Installing chaincode on peer CATPHCM..."
setOrgCATPHCM
peer lifecycle chaincode install "${PWD}/chaincode/${CC_NAME}.tar.gz"

infoln "INFO: Installing chaincode on peer PC02..."
setOrgPC02
peer lifecycle chaincode install "${PWD}/chaincode/${CC_NAME}.tar.gz"

# Query installed chaincode
infoln "INFO: Querying installed chaincode on peer CATPHCM..."
setOrgCATPHCM
peer lifecycle chaincode queryinstalled --output json | jq -r 'try (.installed_chaincodes[].package_id)' | grep ^${PACKAGE_ID}

infoln "INFO: Querying installed chaincode on peer PC02..."
setOrgPC02
peer lifecycle chaincode queryinstalled --output json | jq -r 'try (.installed_chaincodes[].package_id)' | grep ^${PACKAGE_ID}

# Approve and commit chaincode on center-channel
infoln "INFO: Approving and committing chaincode on center-channel..."
setOrgPC02
peer lifecycle chaincode approveformyorg -o localhost:7050 --ordererTLSHostnameOverride catphcm-o1.catphcm.gov.vn --tls --cafile "${PWD}/organizations/memberOrganizations/catphcm.gov.vn/tlsca/tlsca.catphcm.gov.vn-cert.pem" --channelID center-channel --name "${CC_NAME}" --version 1.0 --package-id ${PACKAGE_ID} --sequence 1 --signature-policy "OR('CATPHCM-PMSP.peer')"

setOrgCATPHCM
peer lifecycle chaincode approveformyorg -o localhost:7050 --ordererTLSHostnameOverride catphcm-o1.catphcm.gov.vn --tls --cafile "${PWD}/organizations/memberOrganizations/catphcm.gov.vn/tlsca/tlsca.catphcm.gov.vn-cert.pem" --channelID center-channel --name "${CC_NAME}" --version 1.0 --package-id ${PACKAGE_ID} --sequence 1 --signature-policy "OR('CATPHCM-PMSP.peer')"

peer lifecycle chaincode commit -o localhost:7050 --ordererTLSHostnameOverride catphcm-o1.catphcm.gov.vn --channelID center-channel --name "${CC_NAME}" --version 1.0 --sequence 1 --signature-policy "OR('CATPHCM-PMSP.peer')" --tls --cafile "${PWD}/organizations/memberOrganizations/catphcm.gov.vn/tlsca/tlsca.catphcm.gov.vn-cert.pem" --peerAddresses catphcm-p1.catphcm.gov.vn:7051 --tlsRootCertFiles "${PWD}/organizations/memberOrganizations/catphcm.gov.vn/tlsca/tlsca.catphcm.gov.vn-cert.pem" --peerAddresses pc02-p1.pc02.gov.vn:8051 --tlsRootCertFiles "${PWD}/organizations/memberOrganizations/pc02.gov.vn/tlsca/tlsca.pc02.gov.vn-cert.pem"
sleep 5
successln "INFO: Chaincode approved and committed on center-channel successfully"

# Approve and commit chaincode on pc02-private-channel
infoln "INFO: Approving and committing chaincode on pc02-private-channel..."
setOrgPC02
peer lifecycle chaincode approveformyorg -o localhost:8050 --ordererTLSHostnameOverride pc02-o1.pc02.gov.vn --tls --cafile "${PWD}/organizations/memberOrganizations/pc02.gov.vn/tlsca/tlsca.pc02.gov.vn-cert.pem" --channelID pc02-private-channel --name "${CC_NAME}" --version 1.0 --package-id ${PACKAGE_ID} --sequence 1 --signature-policy "OR('PC02-PMSP.peer')"

peer lifecycle chaincode commit -o localhost:8050 --ordererTLSHostnameOverride pc02-o1.pc02.gov.vn --channelID pc02-private-channel --name "${CC_NAME}" --version 1.0 --sequence 1 --signature-policy "OR('PC02-PMSP.peer')" --tls --cafile "${PWD}/organizations/memberOrganizations/pc02.gov.vn/tlsca/tlsca.pc02.gov.vn-cert.pem" --peerAddresses pc02-p1.pc02.gov.vn:8051 --tlsRootCertFiles "${PWD}/organizations/memberOrganizations/pc02.gov.vn/tlsca/tlsca.pc02.gov.vn-cert.pem"
successln "INFO: Chaincode approved and committed on pc02-private-channel successfully"

# Start Docker container
startDockerContainer
sleep 5

# Invoke chaincode on center-channel
invokeChaincodeCenter() {
    local ordererAddress=$1
    local channel=$2
    local function=$3
    local ordererTLSHostnameOverride=$4
    infoln "INFO: Invoking chaincode on ${channel} with function ${function}"
    peer chaincode invoke -o $ordererAddress --ordererTLSHostnameOverride catphcm-o1.catphcm.gov.vn --tls --cafile "${PWD}/organizations/memberOrganizations/catphcm.gov.vn/tlsca/tlsca.catphcm.gov.vn-cert.pem" -C $channel --name "${CC_NAME}" -c "{\"function\":\"${function}\",\"Args\":[\"dev\"]}" --peerAddresses catphcm-p1.catphcm.gov.vn:7051 --tlsRootCertFiles "${PWD}/organizations/memberOrganizations/catphcm.gov.vn/tlsca/tlsca.catphcm.gov.vn-cert.pem" --peerAddresses pc02-p1.pc02.gov.vn:8051 --tlsRootCertFiles "${PWD}/organizations/memberOrganizations/pc02.gov.vn/tlsca/tlsca.pc02.gov.vn-cert.pem"
    sleep 3
}

invokeChaincodePrivate() {
    local ordererAddress=$1
    local channel=$2
    local function=$3
    local ordererTLSHostnameOverride=$4
    infoln "INFO: Invoking chaincode on ${channel} with function ${function}"
    peer chaincode invoke -o $ordererAddress --ordererTLSHostnameOverride $ordererTLSHostnameOverride --tls --cafile "${PWD}/organizations/memberOrganizations/pc02.gov.vn/tlsca/tlsca.pc02.gov.vn-cert.pem" -C $channel --name "${CC_NAME}" -c "{\"function\":\"${function}\",\"Args\":[\"dev\"]}" --peerAddresses pc02-p1.pc02.gov.vn:8051 --tlsRootCertFiles "${PWD}/organizations/memberOrganizations/pc02.gov.vn/tlsca/tlsca.pc02.gov.vn-cert.pem"
    sleep 3
}

setOrgCATPHCM
invokeChaincodeCenter "localhost:7050" "center-channel" "UserContract:initializeDataDefault"
invokeChaincodeCenter "localhost:7050" "center-channel" "RoleContract:initializeDataDefault"
invokeChaincodeCenter "localhost:7050" "center-channel" "OrganizationContract:initializeDataDefault"
invokeChaincodeCenter "localhost:7050" "center-channel" "PermissionContract:initializeDataDefault"
successln "INFO: Chaincode invoked on center-channel successfully"

# Invoke chaincode on pc02-private-channel
setOrgPC02
invokeChaincodePrivate "localhost:8050" "pc02-private-channel" "UserContract:initializeDataDefault" "pc02-o1.pc02.gov.vn"
invokeChaincodePrivate "localhost:8050" "pc02-private-channel" "RoleContract:initializeDataDefault" "pc02-o1.pc02.gov.vn"
invokeChaincodePrivate "localhost:8050" "pc02-private-channel" "OrganizationContract:initializeDataDefault" "pc02-o1.pc02.gov.vn"
invokeChaincodePrivate "localhost:8050" "pc02-private-channel" "PermissionContract:initializeDataDefault" "pc02-o1.pc02.gov.vn"
successln "INFO: Chaincode invoked on pc02-private-channel successfully"