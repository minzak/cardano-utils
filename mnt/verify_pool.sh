#https://www.coincashew.com/coins/overview-ada/guide-how-to-build-a-haskell-stakepool-node/part-iii-operation/verifying-stake-pool-operation

PRFX=node2
NODE_HOME=/opt/cardano
POOL=/opt/cardano/pool-keys

echo "Your stake pool ID can be computed"
cardano-cli stake-pool id --cold-verification-key-file $POOL/$PRFX.cold.vkey --output-format "hex"
cardano-cli stake-pool id --cold-verification-key-file $POOL/$PRFX.cold.vkey --output-format "bech32"

echo "Now that you have your stake pool ID, verify it's included in the blockchain."
echo "A non-empty string return means you're registered!"
cardano-cli query stake-snapshot --stake-pool-id $(cardano-cli stake-pool id --cold-verification-key-file $POOL/$PRFX.cold.vkey --output-format hex) --mainnet
echo "check it on https://pooltool.io"

