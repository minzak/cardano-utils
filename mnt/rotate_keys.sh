#https://www.coincashew.com/coins/overview-ada/guide-how-to-build-a-haskell-stakepool-node/part-iv-administration/rotating-kes-keys

PRFX=node2
NODE_HOME=/opt/cardano
POOL=/opt/cardano/pool-keys
CRVLM_COLD=/opt/cardano/cold-keys
NEW=/opt/cardano/new-keys

#Generate the KES Key pair:
cardano-cli node key-gen-KES --verification-key-file=$CRVLM_COLD/$PRFX.kes.vkey --signing-key-file=$CRVLM_COLD/$PRFX.kes.skey
chmod 400 $CRVLM_COLD/$PRFX.kes.skey
chmod 400 $CRVLM_COLD/$PRFX.kes.vkey

echo "Copy vrf.vkey and kes.vkey to your cold environment."
cp -vf $CRVLM_COLD/$PRFX.kes.vkey $NEW
cp -vf $CRVLM_COLD/$PRFX.vrf.vkey $NEW

#get the slots per KES period from the genesis file:
echo "slots per KES period:"
cat /opt/cardano/node-core/mainnet-shelley-genesis.json | jq -r .slotsPerKESPeriod
#the current tip of the blockchain:
echo "current tip:"
cardano-cli query tip --mainnet | jq -r .slot
#So we have KES period is:
echo "KES period:"
echo $(($(cardano-cli query tip --mainnet | jq -r .slot) / $(cat /opt/cardano/node-core/mainnet-shelley-genesis.json | jq -r .slotsPerKESPeriod )))
#Now, you can generate the operational certificate:
cardano-cli node issue-op-cert --kes-verification-key-file=$CRVLM_COLD/$PRFX.kes.vkey --cold-signing-key-file=$CRVLM_COLD/$PRFX.cold.skey --operational-certificate-issue-counter=$CRVLM_COLD/$PRFX.cold.counter --out-file=$CRVLM_COLD/$PRFX.op.cert \
--kes-period $(($(cardano-cli query tip --mainnet | jq -r .slot) / $(cat /opt/cardano/node-core/mainnet-shelley-genesis.json | jq -r .slotsPerKESPeriod )))
chmod 400 $CRVLM_COLD/$PRFX.op.cert
cp -vf $CRVLM_COLD/$PRFX.op.cert $NEW
cp -vf $CRVLM_COLD/$PRFX.cold.counter $NEW


#verify_shedule.sh - to check when we can restart node with new keys, binary, etc.
#cp -vf $NEW/$PRFX.kes.skey $POOL
#cp -vf $NEW/$PRFX.kes.vkey $POOL
#cp -vf $NEW/$PRFX.op.cert $POOL
#echo "Restarting Cardano with new keys"
#systemctl restart cardano-core.service

