#!/bin/bash

function createCATPHCM() {
  mkdir -p organizations/memberOrganizations/catphcm.gov.vn/

  export FABRIC_CA_CLIENT_HOME=${PWD}/organizations/memberOrganizations/catphcm.gov.vn/

  set -x
  fabric-ca-client enroll -u https://admin:adminpw@localhost:7054 --caname ca-catphcm --tls.certfiles "${PWD}/organizations/fabric-ca/catphcm/ca-cert.pem"
  { set +x; } 2>/dev/null

  echo 'NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/localhost-7054-ca-catphcm.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/localhost-7054-ca-catphcm.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/localhost-7054-ca-catphcm.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/localhost-7054-ca-catphcm.pem
    OrganizationalUnitIdentifier: orderer' > "${PWD}/organizations/memberOrganizations/catphcm.gov.vn/msp/config.yaml"

  # Since the CA serves as both the organization CA and TLS CA, copy the org's root cert that was generated by CA startup into the org level ca and tlsca directories

  # Copy org1's CA cert to org1's /msp/tlscacerts directory (for use in the channel MSP definition)
  mkdir -p "${PWD}/organizations/memberOrganizations/catphcm.gov.vn/msp/tlscacerts"
  cp "${PWD}/organizations/fabric-ca/catphcm/ca-cert.pem" "${PWD}/organizations/memberOrganizations/catphcm.gov.vn/msp/tlscacerts/ca.crt"

  # Copy org1's CA cert to org1's /tlsca directory (for use by clients)
  mkdir -p "${PWD}/organizations/memberOrganizations/catphcm.gov.vn/tlsca"
  cp "${PWD}/organizations/fabric-ca/catphcm/ca-cert.pem" "${PWD}/organizations/memberOrganizations/catphcm.gov.vn/tlsca/tlsca.catphcm.gov.vn-cert.pem"

  # Copy org1's CA cert to org1's /ca directory (for use by clients)
  mkdir -p "${PWD}/organizations/memberOrganizations/catphcm.gov.vn/ca"
  cp "${PWD}/organizations/fabric-ca/catphcm/ca-cert.pem" "${PWD}/organizations/memberOrganizations/catphcm.gov.vn/ca/ca.catphcm.gov.vn-cert.pem"

  set -x
  fabric-ca-client register --caname ca-catphcm --id.name catphcm-p1 --id.secret catphcm-p1pw --id.type peer --tls.certfiles "${PWD}/organizations/fabric-ca/catphcm/ca-cert.pem"
  { set +x; } 2>/dev/null

  set -x
  fabric-ca-client register --caname ca-catphcm --id.name catphcm-o1 --id.secret catphcm-o1pw --id.type orderer --tls.certfiles "${PWD}/organizations/fabric-ca/catphcm/ca-cert.pem"
  { set +x; } 2>/dev/null

  set -x
  fabric-ca-client register --caname ca-catphcm --id.name catphcm-u1 --id.secret catphcm-u1pw --id.type client --tls.certfiles "${PWD}/organizations/fabric-ca/catphcm/ca-cert.pem"
  { set +x; } 2>/dev/null

  set -x
  fabric-ca-client register --caname ca-catphcm --id.name catphcm-a1 --id.secret catphcm-a1pw --id.type admin --tls.certfiles "${PWD}/organizations/fabric-ca/catphcm/ca-cert.pem"
  { set +x; } 2>/dev/null

  set -x
  fabric-ca-client enroll -u https://catphcm-p1:catphcm-p1pw@localhost:7054 --caname ca-catphcm -M "${PWD}/organizations/memberOrganizations/catphcm.gov.vn/peers/catphcm-p1.catphcm.gov.vn/msp" --csr.hosts catphcm-p1.catphcm.gov.vn --tls.certfiles "${PWD}/organizations/fabric-ca/catphcm/ca-cert.pem"
  { set +x; } 2>/dev/null

  cp "${PWD}/organizations/memberOrganizations/catphcm.gov.vn/msp/config.yaml" "${PWD}/organizations/memberOrganizations/catphcm.gov.vn/peers/catphcm-p1.catphcm.gov.vn/msp/config.yaml"

  set -x
  fabric-ca-client enroll -u https://catphcm-p1:catphcm-p1pw@localhost:7054 --caname ca-catphcm -M "${PWD}/organizations/memberOrganizations/catphcm.gov.vn/peers/catphcm-p1.catphcm.gov.vn/tls" --enrollment.profile tls --csr.hosts catphcm-p1.catphcm.gov.vn --csr.hosts localhost --tls.certfiles "${PWD}/organizations/fabric-ca/catphcm/ca-cert.pem"
  { set +x; } 2>/dev/null

  set -x
  fabric-ca-client enroll -u https://catphcm-o1:catphcm-o1pw@localhost:7054 --caname ca-catphcm -M "${PWD}/organizations/memberOrganizations/catphcm.gov.vn/orderers/catphcm-o1.catphcm.gov.vn/msp" --csr.hosts catphcm-o1.catphcm.gov.vn --csr.hosts localhost --tls.certfiles "${PWD}/organizations/fabric-ca/catphcm/ca-cert.pem"
  { set +x; } 2>/dev/null

  cp "${PWD}/organizations/memberOrganizations/catphcm.gov.vn/msp/config.yaml" "${PWD}/organizations/memberOrganizations/catphcm.gov.vn/orderers/catphcm-o1.catphcm.gov.vn/msp/config.yaml"

  set -x
  fabric-ca-client enroll -u https://catphcm-o1:catphcm-o1pw@localhost:7054 --caname ca-catphcm -M "${PWD}/organizations/memberOrganizations/catphcm.gov.vn/orderers/catphcm-o1.catphcm.gov.vn/tls" --enrollment.profile tls --csr.hosts catphcm-o1.catphcm.gov.vn --csr.hosts localhost --tls.certfiles "${PWD}/organizations/fabric-ca/catphcm/ca-cert.pem"
  { set +x; } 2>/dev/null

  # Copy the tls CA cert, server cert, server keystore to well known file names in the peer's tls directory that are referenced by peer startup config
  cp "${PWD}/organizations/memberOrganizations/catphcm.gov.vn/peers/catphcm-p1.catphcm.gov.vn/tls/tlscacerts/"* "${PWD}/organizations/memberOrganizations/catphcm.gov.vn/peers/catphcm-p1.catphcm.gov.vn/tls/ca.crt"
  cp "${PWD}/organizations/memberOrganizations/catphcm.gov.vn/peers/catphcm-p1.catphcm.gov.vn/tls/signcerts/"* "${PWD}/organizations/memberOrganizations/catphcm.gov.vn/peers/catphcm-p1.catphcm.gov.vn/tls/server.crt"
  cp "${PWD}/organizations/memberOrganizations/catphcm.gov.vn/peers/catphcm-p1.catphcm.gov.vn/tls/keystore/"* "${PWD}/organizations/memberOrganizations/catphcm.gov.vn/peers/catphcm-p1.catphcm.gov.vn/tls/server.key"
  
  cp "${PWD}/organizations/memberOrganizations/catphcm.gov.vn/orderers/catphcm-o1.catphcm.gov.vn/tls/tlscacerts/"* "${PWD}/organizations/memberOrganizations/catphcm.gov.vn/orderers/catphcm-o1.catphcm.gov.vn/tls/ca.crt"
  cp "${PWD}/organizations/memberOrganizations/catphcm.gov.vn/orderers/catphcm-o1.catphcm.gov.vn/tls/signcerts/"* "${PWD}/organizations/memberOrganizations/catphcm.gov.vn/orderers/catphcm-o1.catphcm.gov.vn/tls/server.crt"
  cp "${PWD}/organizations/memberOrganizations/catphcm.gov.vn/orderers/catphcm-o1.catphcm.gov.vn/tls/keystore/"* "${PWD}/organizations/memberOrganizations/catphcm.gov.vn/orderers/catphcm-o1.catphcm.gov.vn/tls/server.key"

  mkdir -p "${PWD}/organizations/memberOrganizations/catphcm.gov.vn/orderers/catphcm-o1.catphcm.gov.vn/msp/tlscacerts"
  cp "${PWD}/organizations/memberOrganizations/catphcm.gov.vn/orderers/catphcm-o1.catphcm.gov.vn/tls/tlscacerts/"* "${PWD}/organizations/memberOrganizations/catphcm.gov.vn/orderers/catphcm-o1.catphcm.gov.vn/msp/tlscacerts/tlsca.catphcm.gov.vn-cert.pem" 

  set -x
  fabric-ca-client enroll -u https://catphcm-u1:catphcm-u1pw@localhost:7054 --caname ca-catphcm -M "${PWD}/organizations/memberOrganizations/catphcm.gov.vn/users/catphcm-u1@catphcm.gov.vn/msp" --tls.certfiles "${PWD}/organizations/fabric-ca/catphcm/ca-cert.pem"
  { set +x; } 2>/dev/null

  cp "${PWD}/organizations/memberOrganizations/catphcm.gov.vn/msp/config.yaml" "${PWD}/organizations/memberOrganizations/catphcm.gov.vn/users/catphcm-u1@catphcm.gov.vn/msp/config.yaml"

  set -x
  fabric-ca-client enroll -u https://catphcm-a1:catphcm-a1pw@localhost:7054 --caname ca-catphcm -M "${PWD}/organizations/memberOrganizations/catphcm.gov.vn/users/catphcm-a1@catphcm.gov.vn/msp" --tls.certfiles "${PWD}/organizations/fabric-ca/catphcm/ca-cert.pem"
  { set +x; } 2>/dev/null

  cp "${PWD}/organizations/memberOrganizations/catphcm.gov.vn/msp/config.yaml" "${PWD}/organizations/memberOrganizations/catphcm.gov.vn/users/catphcm-a1@catphcm.gov.vn/msp/config.yaml"
}

function createPC02() {
  mkdir -p organizations/memberOrganizations/pc02.gov.vn/

  export FABRIC_CA_CLIENT_HOME=${PWD}/organizations/memberOrganizations/pc02.gov.vn/

  set -x
  fabric-ca-client enroll -u https://admin:adminpw@localhost:8054 --caname ca-pc02 --tls.certfiles "${PWD}/organizations/fabric-ca/pc02/ca-cert.pem"
  { set +x; } 2>/dev/null

  echo 'NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/localhost-8054-ca-pc02.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/localhost-8054-ca-pc02.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/localhost-8054-ca-pc02.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/localhost-8054-ca-pc02.pem
    OrganizationalUnitIdentifier: orderer' > "${PWD}/organizations/memberOrganizations/pc02.gov.vn/msp/config.yaml"

  # Since the CA serves as both the organization CA and TLS CA, copy the org's root cert that was generated by CA startup into the org level ca and tlsca directories

  # Copy org1's CA cert to org1's /msp/tlscacerts directory (for use in the channel MSP definition)
  mkdir -p "${PWD}/organizations/memberOrganizations/pc02.gov.vn/msp/tlscacerts"
  cp "${PWD}/organizations/fabric-ca/pc02/ca-cert.pem" "${PWD}/organizations/memberOrganizations/pc02.gov.vn/msp/tlscacerts/ca.crt"

  # Copy org1's CA cert to org1's /tlsca directory (for use by clients)
  mkdir -p "${PWD}/organizations/memberOrganizations/pc02.gov.vn/tlsca"
  cp "${PWD}/organizations/fabric-ca/pc02/ca-cert.pem" "${PWD}/organizations/memberOrganizations/pc02.gov.vn/tlsca/tlsca.pc02.gov.vn-cert.pem"

  # Copy org1's CA cert to org1's /ca directory (for use by clients)
  mkdir -p "${PWD}/organizations/memberOrganizations/pc02.gov.vn/ca"
  cp "${PWD}/organizations/fabric-ca/pc02/ca-cert.pem" "${PWD}/organizations/memberOrganizations/pc02.gov.vn/ca/ca.pc02.gov.vn-cert.pem"

  set -x
  fabric-ca-client register --caname ca-pc02 --id.name pc02-p1 --id.secret pc02-p1pw --id.type peer --tls.certfiles "${PWD}/organizations/fabric-ca/pc02/ca-cert.pem"
  { set +x; } 2>/dev/null

  set -x
  fabric-ca-client register --caname ca-pc02 --id.name pc02-o1 --id.secret pc02-o1pw --id.type orderer --tls.certfiles "${PWD}/organizations/fabric-ca/pc02/ca-cert.pem"
  { set +x; } 2>/dev/null

  set -x
  fabric-ca-client register --caname ca-pc02 --id.name pc02-u1 --id.secret pc02-u1pw --id.type client --tls.certfiles "${PWD}/organizations/fabric-ca/pc02/ca-cert.pem"
  { set +x; } 2>/dev/null

  set -x
  fabric-ca-client register --caname ca-pc02 --id.name pc02-a1 --id.secret pc02-a1pw --id.type admin --tls.certfiles "${PWD}/organizations/fabric-ca/pc02/ca-cert.pem"
  { set +x; } 2>/dev/null

  set -x
  fabric-ca-client enroll -u https://pc02-p1:pc02-p1pw@localhost:8054 --caname ca-pc02 -M "${PWD}/organizations/memberOrganizations/pc02.gov.vn/peers/pc02-p1.pc02.gov.vn/msp" --csr.hosts pc02-p1.pc02.gov.vn --tls.certfiles "${PWD}/organizations/fabric-ca/pc02/ca-cert.pem"
  { set +x; } 2>/dev/null

  cp "${PWD}/organizations/memberOrganizations/pc02.gov.vn/msp/config.yaml" "${PWD}/organizations/memberOrganizations/pc02.gov.vn/peers/pc02-p1.pc02.gov.vn/msp/config.yaml"

  set -x
  fabric-ca-client enroll -u https://pc02-p1:pc02-p1pw@localhost:8054 --caname ca-pc02 -M "${PWD}/organizations/memberOrganizations/pc02.gov.vn/peers/pc02-p1.pc02.gov.vn/tls" --enrollment.profile tls --csr.hosts pc02-p1.pc02.gov.vn --csr.hosts localhost --tls.certfiles "${PWD}/organizations/fabric-ca/pc02/ca-cert.pem"
  { set +x; } 2>/dev/null

  set -x
  fabric-ca-client enroll -u https://pc02-o1:pc02-o1pw@localhost:8054 --caname ca-pc02 -M "${PWD}/organizations/memberOrganizations/pc02.gov.vn/orderers/pc02-o1.pc02.gov.vn/msp" --csr.hosts pc02-o1.pc02.gov.vn --csr.hosts localhost --tls.certfiles "${PWD}/organizations/fabric-ca/pc02/ca-cert.pem"
  { set +x; } 2>/dev/null

  cp "${PWD}/organizations/memberOrganizations/pc02.gov.vn/msp/config.yaml" "${PWD}/organizations/memberOrganizations/pc02.gov.vn/orderers/pc02-o1.pc02.gov.vn/msp/config.yaml"

  set -x
  fabric-ca-client enroll -u https://pc02-o1:pc02-o1pw@localhost:8054 --caname ca-pc02 -M "${PWD}/organizations/memberOrganizations/pc02.gov.vn/orderers/pc02-o1.pc02.gov.vn/tls" --enrollment.profile tls --csr.hosts pc02-o1.pc02.gov.vn --csr.hosts localhost --tls.certfiles "${PWD}/organizations/fabric-ca/pc02/ca-cert.pem"
  { set +x; } 2>/dev/null

  # Copy the tls CA cert, server cert, server keystore to well known file names in the peer's tls directory that are referenced by peer startup config
  cp "${PWD}/organizations/memberOrganizations/pc02.gov.vn/peers/pc02-p1.pc02.gov.vn/tls/tlscacerts/"* "${PWD}/organizations/memberOrganizations/pc02.gov.vn/peers/pc02-p1.pc02.gov.vn/tls/ca.crt"
  cp "${PWD}/organizations/memberOrganizations/pc02.gov.vn/peers/pc02-p1.pc02.gov.vn/tls/signcerts/"* "${PWD}/organizations/memberOrganizations/pc02.gov.vn/peers/pc02-p1.pc02.gov.vn/tls/server.crt"
  cp "${PWD}/organizations/memberOrganizations/pc02.gov.vn/peers/pc02-p1.pc02.gov.vn/tls/keystore/"* "${PWD}/organizations/memberOrganizations/pc02.gov.vn/peers/pc02-p1.pc02.gov.vn/tls/server.key"
  
  cp "${PWD}/organizations/memberOrganizations/pc02.gov.vn/orderers/pc02-o1.pc02.gov.vn/tls/tlscacerts/"* "${PWD}/organizations/memberOrganizations/pc02.gov.vn/orderers/pc02-o1.pc02.gov.vn/tls/ca.crt"
  cp "${PWD}/organizations/memberOrganizations/pc02.gov.vn/orderers/pc02-o1.pc02.gov.vn/tls/signcerts/"* "${PWD}/organizations/memberOrganizations/pc02.gov.vn/orderers/pc02-o1.pc02.gov.vn/tls/server.crt"
  cp "${PWD}/organizations/memberOrganizations/pc02.gov.vn/orderers/pc02-o1.pc02.gov.vn/tls/keystore/"* "${PWD}/organizations/memberOrganizations/pc02.gov.vn/orderers/pc02-o1.pc02.gov.vn/tls/server.key"

  mkdir -p "${PWD}/organizations/memberOrganizations/pc02.gov.vn/orderers/pc02-o1.pc02.gov.vn/msp/tlscacerts"
  cp "${PWD}/organizations/memberOrganizations/pc02.gov.vn/orderers/pc02-o1.pc02.gov.vn/tls/tlscacerts/"* "${PWD}/organizations/memberOrganizations/pc02.gov.vn/orderers/pc02-o1.pc02.gov.vn/msp/tlscacerts/tlsca.pc02.gov.vn-cert.pem"

  set -x
  fabric-ca-client enroll -u https://pc02-u1:pc02-u1pw@localhost:8054 --caname ca-pc02 -M "${PWD}/organizations/memberOrganizations/pc02.gov.vn/users/pc02-u1@pc02.gov.vn/msp" --tls.certfiles "${PWD}/organizations/fabric-ca/pc02/ca-cert.pem"
  { set +x; } 2>/dev/null

  cp "${PWD}/organizations/memberOrganizations/pc02.gov.vn/msp/config.yaml" "${PWD}/organizations/memberOrganizations/pc02.gov.vn/users/pc02-u1@pc02.gov.vn/msp/config.yaml"

  set -x
  fabric-ca-client enroll -u https://pc02-a1:pc02-a1pw@localhost:8054 --caname ca-pc02 -M "${PWD}/organizations/memberOrganizations/pc02.gov.vn/users/pc02-a1@pc02.gov.vn/msp" --tls.certfiles "${PWD}/organizations/fabric-ca/pc02/ca-cert.pem"
  { set +x; } 2>/dev/null

  cp "${PWD}/organizations/memberOrganizations/pc02.gov.vn/msp/config.yaml" "${PWD}/organizations/memberOrganizations/pc02.gov.vn/users/pc02-a1@pc02.gov.vn/msp/config.yaml"
}
function createOrgs(){
  createCATPHCM
  createPC02
}