docker compose -f ${PWD}/docker/docker-compose-catphcm.yaml down
docker compose -f ${PWD}/docker/docker-compose-pc02.yaml down
docker compose -f ${PWD}/docker/docker-compose-ca.yaml down

docker rm -f $(docker ps -a | grep ccaas_image | awk '{print $1}') 2>/dev/null 
sleep 5

docker rmi -f $(docker images --filter "reference=*ccaas_image*" --quiet --no-trunc | xargs) 2>/dev/null 
docker rmi -f $(docker images --filter "reference=*chaincode*" --quiet --no-trunc | xargs) 2>/dev/null

docker volume rm $(docker volume ls -qf dangling=true) 2>/dev/null 

# docker volume ls --quiet --filter "name=docker_" | xargs -r docker volume rm 2>/dev/null

sudo rm -r -f ${PWD}/organizations/fabric-ca 2>/dev/null 
sudo rm -r -f ${PWD}/organizations/memberOrganizations 2>/dev/null 
sudo rm -f ${PWD}/channel/CENTER_CHANNEL/*.block 2>/dev/null 
sudo rm -f ${PWD}/channel/PC02_PRIVATE_CHANNEL/*.block 2>/dev/null 
sudo rm -f ${PWD}/chaincode/*.tar.gz 2>/dev/null 