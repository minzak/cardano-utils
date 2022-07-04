#curl -s -X GET http://localhost:8090/v2/network/information | jq
#curl -s -X GET http://localhost:8090/v2/network/information | jq .sync_progress

#curl -s -X GET http://localhost:8090/v2/wallets/xxxx | jq


echo $(cat /opt/cardano/pool-keys/node2.payment.addr) | ./cardano-address address inspect
