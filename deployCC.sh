. registerEnroll.sh
. setEnvVar.sh
CHAINCODE_NAME=$1
# Install path tool
export PATH=${PWD}/bin:$PATH
#Check chaincode
if [ ! -d "${PWD}/../dev_extcc" ]; then
    echo "Not found folder chaincode dev_extc"
    exit 1
fi

cd ${PWD}/../dev_extcc

npm install
npm run build
sleep 5

cd ${PWD}/../private-blockchain
mkdir -p chaincode

#Package chaincode
setOrgCATPHCM
peer lifecycle chaincode package ${PWD}/chaincode/${CHAINCODE_NAME}.tar.gz --path ${PWD}/../dev_extcc --lang node --label ${CHAINCODE_NAME}_1.0
sleep 3
PACKAGE_ID=$(peer lifecycle chaincode calculatepackageid ${PWD}/chaincode/${CHAINCODE_NAME}.tar.gz)

#Install chanicode on peer CATPHCM
setOrgCATPHCM
peer lifecycle chaincode install ${PWD}/chaincode/${CHAINCODE_NAME}.tar.gz

#Install chanicode on peer PC02
setOrgPC02
peer lifecycle chaincode install ${PWD}/chaincode/${CHAINCODE_NAME}.tar.gz

#Query chanicode on peer CATPHCM
setOrgCATPHCM
peer lifecycle chaincode queryinstalled --output json | jq -r 'try (.installed_chaincodes[].package_id)' | grep ^${PACKAGE_ID} 

#Approved chaincode on peer CATPHCM
setOrgCATPHCM
peer lifecycle chaincode approveformyorg -o localhost:7050 --ordererTLSHostnameOverride catphcm-o1.catphcm.gov.vn --tls --cafile ${PWD}/organizations/memberOrganizations/catphcm.gov.vn/tlsca/tlsca.catphcm.gov.vn-cert.pem --channelID center-channel --name ${CHAINCODE_NAME} --version 1.0 --package-id ${PACKAGE_ID} --sequence 1 --signature-policy "OR('CATPHCM-PMSP.peer')"

#Approved chaincode on peer PC02
setOrgPC02
peer lifecycle chaincode approveformyorg -o localhost:7050 --ordererTLSHostnameOverride catphcm-o1.catphcm.gov.vn --tls --cafile ${PWD}/organizations/memberOrganizations/catphcm.gov.vn/tlsca/tlsca.catphcm.gov.vn-cert.pem --channelID center-channel --name ${CHAINCODE_NAME} --version 1.0 --package-id ${PACKAGE_ID} --sequence 1 --signature-policy "OR('CATPHCM-PMSP.peer')"

#Commit chaincode
peer lifecycle chaincode commit -o localhost:7050 --ordererTLSHostnameOverride catphcm-o1.catphcm.gov.vn --channelID center-channel --name ${CHAINCODE_NAME} --version 1.0 --sequence 1 --signature-policy "OR('CATPHCM-PMSP.peer')" --tls --cafile ${PWD}/organizations/memberOrganizations/catphcm.gov.vn/tlsca/tlsca.catphcm.gov.vn-cert.pem --peerAddresses catphcm-p1.catphcm.gov.vn:7051 --tlsRootCertFiles ${PWD}/organizations/memberOrganizations/catphcm.gov.vn/tlsca/tlsca.catphcm.gov.vn-cert.pem --peerAddresses pc02-p1.pc02.gov.vn:8051 --tlsRootCertFiles ${PWD}/organizations/memberOrganizations/pc02.gov.vn/tlsca/tlsca.pc02.gov.vn-cert.pem
sleep 5
#Invoke chaincode
peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride catphcm-o1.catphcm.gov.vn --tls --cafile ${PWD}/organizations/memberOrganizations/catphcm.gov.vn/tlsca/tlsca.catphcm.gov.vn-cert.pem -C center-channel --name ${CHAINCODE_NAME} -c '{"function":"UserContract:initializeDataDefault","Args":["dev"]}' --peerAddresses catphcm-p1.catphcm.gov.vn:7051 --tlsRootCertFiles ${PWD}/organizations/memberOrganizations/catphcm.gov.vn/tlsca/tlsca.catphcm.gov.vn-cert.pem --peerAddresses pc02-p1.pc02.gov.vn:8051 --tlsRootCertFiles ${PWD}/organizations/memberOrganizations/pc02.gov.vn/tlsca/tlsca.pc02.gov.vn-cert.pem
sleep 1
peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride catphcm-o1.catphcm.gov.vn --tls --cafile ${PWD}/organizations/memberOrganizations/catphcm.gov.vn/tlsca/tlsca.catphcm.gov.vn-cert.pem -C center-channel --name ${CHAINCODE_NAME} -c '{"function":"RoleContract:initializeDataDefault","Args":["dev"]}' --peerAddresses catphcm-p1.catphcm.gov.vn:7051 --tlsRootCertFiles ${PWD}/organizations/memberOrganizations/catphcm.gov.vn/tlsca/tlsca.catphcm.gov.vn-cert.pem --peerAddresses pc02-p1.pc02.gov.vn:8051 --tlsRootCertFiles ${PWD}/organizations/memberOrganizations/pc02.gov.vn/tlsca/tlsca.pc02.gov.vn-cert.pem
sleep 1
peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride catphcm-o1.catphcm.gov.vn --tls --cafile ${PWD}/organizations/memberOrganizations/catphcm.gov.vn/tlsca/tlsca.catphcm.gov.vn-cert.pem -C center-channel --name ${CHAINCODE_NAME} -c '{"function":"OrganizationContract:initializeDataDefault","Args":["dev"]}'  --peerAddresses catphcm-p1.catphcm.gov.vn:7051 --tlsRootCertFiles ${PWD}/organizations/memberOrganizations/catphcm.gov.vn/tlsca/tlsca.catphcm.gov.vn-cert.pem --peerAddresses pc02-p1.pc02.gov.vn:8051 --tlsRootCertFiles ${PWD}/organizations/memberOrganizations/pc02.gov.vn/tlsca/tlsca.pc02.gov.vn-cert.pem
sleep 1
peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride catphcm-o1.catphcm.gov.vn --tls --cafile ${PWD}/organizations/memberOrganizations/catphcm.gov.vn/tlsca/tlsca.catphcm.gov.vn-cert.pem -C center-channel --name ${CHAINCODE_NAME} -c '{"function":"PermissionContract:initializeDataDefault","Args":["dev"]}'


#Package chaincode in channel private
setOrgPC02
peer lifecycle chaincode package ${PWD}/chaincode/private_${CHAINCODE_NAME}.tar.gz --path ${PWD}/../dev_extcc --lang node --label private_${CHAINCODE_NAME}_1.0
sleep 3
PACKAGE_ID=$(peer lifecycle chaincode calculatepackageid ${PWD}/chaincode/private_${CHAINCODE_NAME}.tar.gz)

#Install chanicode on peer PC02
setOrgPC02
peer lifecycle chaincode install ${PWD}/chaincode/private_${CHAINCODE_NAME}.tar.gz

#Query chanicode on peer PC02
setOrgPC02
peer lifecycle chaincode queryinstalled --output json | jq -r 'try (.installed_chaincodes[].package_id)' | grep ^${PACKAGE_ID} 

#Approved chaincode on peer PC02
setOrgPC02
peer lifecycle chaincode approveformyorg -o localhost:8050 --ordererTLSHostnameOverride pc02-o1.pc02.gov.vn --tls --cafile ${PWD}/organizations/memberOrganizations/pc02.gov.vn/tlsca/tlsca.pc02.gov.vn-cert.pem --channelID pc02-private-channel --name private_${CHAINCODE_NAME} --version 1.0 --package-id ${PACKAGE_ID} --sequence 1 --signature-policy "OR('PC02-PMSP.peer')"

#Commit chaincode
peer lifecycle chaincode commit -o localhost:8050 --ordererTLSHostnameOverride pc02-o1.pc02.gov.vn --channelID pc02-private-channel --name private_${CHAINCODE_NAME} --version 1.0 --sequence 1 --signature-policy "OR('PC02-PMSP.peer')" --tls --cafile ${PWD}/organizations/memberOrganizations/pc02.gov.vn/tlsca/tlsca.pc02.gov.vn-cert.pem --peerAddresses pc02-p1.pc02.gov.vn:8051 --tlsRootCertFiles ${PWD}/organizations/memberOrganizations/pc02.gov.vn/tlsca/tlsca.pc02.gov.vn-cert.pem

#Invoke chaincode
peer chaincode invoke -o localhost:8050 --ordererTLSHostnameOverride pc02-o1.pc02.gov.vn --tls --cafile ${PWD}/organizations/memberOrganizations/pc02.gov.vn/tlsca/tlsca.pc02.gov.vn-cert.pem -C pc02-private-channel -n private_${CHAINCODE_NAME} -c '{"function":"UserContract:initializeDataDefault","Args":["dev"]}'
sleep 1
peer chaincode invoke -o localhost:8050 --ordererTLSHostnameOverride pc02-o1.pc02.gov.vn --tls --cafile ${PWD}/organizations/memberOrganizations/pc02.gov.vn/tlsca/tlsca.pc02.gov.vn-cert.pem -C pc02-private-channel -n private_${CHAINCODE_NAME} -c '{"function":"RoleContract:initializeDataDefault","Args":["dev"]}'
sleep 1
peer chaincode invoke -o localhost:8050 --ordererTLSHostnameOverride pc02-o1.pc02.gov.vn --tls --cafile ${PWD}/organizations/memberOrganizations/pc02.gov.vn/tlsca/tlsca.pc02.gov.vn-cert.pem -C pc02-private-channel -n private_${CHAINCODE_NAME} -c '{"function":"OrganizationContract:initializeDataDefault","Args":["dev"]}'
sleep 1
peer chaincode invoke -o localhost:8050 --ordererTLSHostnameOverride pc02-o1.pc02.gov.vn --tls --cafile ${PWD}/organizations/memberOrganizations/pc02.gov.vn/tlsca/tlsca.pc02.gov.vn-cert.pem -C pc02-private-channel -n private_${CHAINCODE_NAME} -c '{"function":"PermissionContract:initializeDataDefault","Args":["dev"]}'