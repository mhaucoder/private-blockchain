docker compose -f docker-compose-catphcm.yaml down
docker compose -f docker-compose-pc02.yaml down
docker compose -f docker-compose-ca.yaml down

docker volume rm private-blockchain_catphcm-p1.catphcm.gov.vn
docker volume rm private-blockchain_catphcm-o1.catphcm.gov.vn
docker volume rm private-blockchain_pc02-p1.pc02.gov.vn
docker volume rm private-blockchain_pc02-o1.pc02.gov.vn
sudo docker volume rm $(docker volume ls -qf dangling=true)

sudo rm -r -f ./organizations/fabric-ca
sudo rm -r -f ./organizations/memberOrganizations
sudo rm -f ./channel/CENTER_CHANNEL/*.block
sudo rm -f ./channel/PC02_PRIVATE_CHANNEL/*.block
sudo rm -f ./chaincode/*.tar.gz

