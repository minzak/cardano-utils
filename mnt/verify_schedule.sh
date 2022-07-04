#
PRFX=node2
POOL=/opt/cardano/pool-keys

echo "Your stake pool ID can be computed"
ID=$(cardano-cli stake-pool id --cold-verification-key-file $POOL/$PRFX.cold.vkey --output-format hex)
echo "Pool ID: $ID"

echo "Query leadership-schedule"

cardano-cli query leadership-schedule \
   --mainnet \
   --genesis /opt/cardano/node-core/mainnet-shelley-genesis.json \
   --stake-pool-id  $ID \
   --vrf-signing-key-file $POOL/$PRFX.vrf.skey \
   --current
