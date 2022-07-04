#https://github.com/input-output-hk/cardano-node/blob/master/doc/stake-pool-operations/keys_and_addresses.md

PRFX=node2
POOL=/opt/cardano/pool-keys

echo "Query the balance of an address: $(cat $POOL/$PRFX.payment.addr)"
cardano-cli query utxo --mainnet --address $(cat $POOL/$PRFX.payment.addr)

echo "Check the balance of the rewards address: $(cat $POOL/$PRFX.stake.addr)"
cardano-cli query stake-address-info --mainnet --address $(cat $POOL/$PRFX.stake.addr)

#echo "Check the balance of the rewards address: $(cat $POOL/$PRFX.send2.addr)"
#cardano-cli query stake-address-info --mainnet --address $(cat $POOL/$PRFX.send2.addr)
