NODE_CONFIG=mainnet

mkdir -p /opt/cardano/node-relay/
cd /opt/cardano/node-relay/

wget -N https://hydra.iohk.io/job/Cardano/cardano-node/cardano-deployment/latest-finished/download/1/${NODE_CONFIG}-config.json
wget -N https://hydra.iohk.io/job/Cardano/cardano-node/cardano-deployment/latest-finished/download/1/${NODE_CONFIG}-byron-genesis.json
wget -N https://hydra.iohk.io/job/Cardano/cardano-node/cardano-deployment/latest-finished/download/1/${NODE_CONFIG}-shelley-genesis.json
wget -N https://hydra.iohk.io/job/Cardano/cardano-node/cardano-deployment/latest-finished/download/1/${NODE_CONFIG}-alonzo-genesis.json
wget -N https://hydra.iohk.io/job/Cardano/cardano-node/cardano-deployment/latest-finished/download/1/${NODE_CONFIG}-topology.json

sed -i ${NODE_CONFIG}-config.json -e "s/TraceBlockFetchDecisions\": false/TraceBlockFetchDecisions\": true/g"
sed -i ${NODE_CONFIG}-config.json -e "s/TraceMempool\": true/TraceMempool\": false/g"

echo export CARDANO_NODE_SOCKET_PATH="/opt/cardano/node-relay/db/node.socket" >> $HOME/.bashrc
source $HOME/.bashrc

