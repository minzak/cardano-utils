#node-core
/opt/cardano/cardano-node run --topology=/opt/cardano/node-core/mainnet-topology.json --config=/opt/cardano/node-core/mainnet-config.json \
--database-path=/opt/cardano/node-core/db --socket-path=/opt/cardano/node-core/db/node.socket --port 3000

#--shelley-kes-key=/opt/cardano/pool-keys/node2.kes.skey --shelley-vrf-key=/opt/cardano/pool-keys/node2.vrf.skey \
#--shelley-operational-certificate=/opt/cardano/pool-keys/node.cert \
