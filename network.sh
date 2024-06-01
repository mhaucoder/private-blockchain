#!/bin/bash
# Lấy đối số đầu tiên
function_name=$1

# Kiểm tra đối số và gọi hàm tương ứng
case $function_name in
  "up")
    ./scripts/upNetwork.sh
    ;;
  "down")
    ./scripts/downNetwork.sh
    ;;
  "deployCC")
    ./scripts/deployCC.sh $2
    ;;
  "deployCCAAS")
    ./scripts/deployCCAAS.sh $2
    ;;
  *)
    echo "Function $function_name not found"
    echo "Usage: ./run.sh [function_name] [args]"
    echo "Functions:"
    echo "  - up: start the fabric blockchain network"
    echo "  - down: stop the fabric blockchain network"
    echo "  - deployCC <chaincode-name>: deploy new chaincode"
    exit 1
    ;;
esac
