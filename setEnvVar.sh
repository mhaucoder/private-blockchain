function setOrgCATPHCM(){
    export CORE_PEER_TLS_ENABLED=true
    export FABRIC_CFG_PATH=$PWD/organizations/peercfg
    export CORE_PEER_LOCALMSPID="CATPHCM-PMSP"
    export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/memberOrganizations/catphcm.gov.vn/users/catphcm-a1@catphcm.gov.vn/msp
    export CORE_PEER_ADDRESS=localhost:7051
    export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/memberOrganizations/catphcm.gov.vn/tlsca/tlsca.catphcm.gov.vn-cert.pem
}
function setOrgPC02(){
    export CORE_PEER_TLS_ENABLED=true
    export FABRIC_CFG_PATH=$PWD/organizations/peercfg
    export CORE_PEER_LOCALMSPID="PC02-PMSP"
    export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/memberOrganizations/pc02.gov.vn/users/pc02-a1@pc02.gov.vn/msp
    export CORE_PEER_ADDRESS=localhost:8051
    export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/memberOrganizations/pc02.gov.vn/tlsca/tlsca.pc02.gov.vn-cert.pem
}