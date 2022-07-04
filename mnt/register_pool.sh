#https://www.coincashew.com/coins/overview-ada/guide-how-to-build-a-haskell-stakepool-node/part-iii-operation/registering-your-stake-pool

#Cryptovolumes must be mounted
#/mnt/crypt_mount_cold_vlm.sh

PRFX=node2
NODE_HOME=/opt/cardano
POOL=/opt/cardano/pool-keys
CRVLM_COLD=/opt/cardano/cold-keys


#ticker must be between 3-9 characters in length. Characters must be A-Z and 0-9 only.
#description cannot exceed 255 characters in length.

cat > $NODE_HOME/$PRFX.poolMetaData.json << EOF
{
  "name": "BIZLEVEL Validator",
  "description": "BizLevel it is a private node.",
  "ticker": "BIZL2",
  "homepage": "https://bizlevel.net/validator"
}
EOF

echo "Calculate the hash of your metadata file. It's saved to poolMetaDataHash.txt"
cardano-cli stake-pool metadata-hash --pool-metadata-file $NODE_HOME/$PRFX.poolMetaData.json > $NODE_HOME/$PRFX.poolMetaDataHash.txt

echo "Copy poolMetaData.json to your cold environment."
cp -v $NODE_HOME/$PRFX.poolMetaData.json $CRVLM_COLD
echo "Copy poolMetaDataHash.txt to your cold environment."
cp -v $NODE_HOME/$PRFX.poolMetaDataHash.txt $CRVLM_COLD

echo "upload your poolMetaData.json file to a Web"
scp -P22 -i ~/.ssh/id_ed25519 /opt/cardano/$PRFX.poolMetaData.json root@cardano.bizlevel.net:/opt/cardano/cardano/

#echo "Verify the metadata hashes by comparing your uploaded .json file and your local .json file's hash."
#cardano-cli stake-pool metadata-hash --pool-metadata-file < "$(curl -s -L https://cardano.bizlevel.net/$PRFX.poolMetaData.json)"
#cat $NODE_HOME/$PRFX.poolMetaDataHash.txt


#metadata-url must be no longer than 64 characters.
#Here we are pledging 10 ADA with a fixed pool cost of 345 ADA and a pool margin of 5%.
cardano-cli stake-pool registration-certificate \
    --cold-verification-key-file $CRVLM_COLD/$PRFX.cold.vkey \
    --vrf-verification-key-file $CRVLM_COLD/$PRFX.vrf.vkey \
    --pool-pledge 1000000000 \
    --pool-cost 340000000 \
    --pool-margin 0.02 \
    --pool-reward-account-verification-key-file $CRVLM_COLD/$PRFX.stake.vkey \
    --pool-owner-stake-verification-key-file $CRVLM_COLD/$PRFX.stake.vkey \
    --mainnet \
    --single-host-pool-relay relay1-ada.bizlevel.net --pool-relay-port 3001 \
    --single-host-pool-relay relay2-ada.bizlevel.net --pool-relay-port 3002 \
    --metadata-url https://bizlevel.net/cardano/$PRFX.poolMetaData.json \
    --metadata-hash $(cat $CRVLM_COLD/$PRFX.poolMetaDataHash.txt) \
    --out-file $CRVLM_COLD/$PRFX.pool-registration.cert

echo "Copy pool.cert to your hot environment."
cp -v $CRVLM_COLD/$PRFX.pool-registration.cert $POOL

echo "Pledge stake to your stake pool."
cardano-cli stake-address delegation-certificate \
    --stake-verification-key-file $CRVLM_COLD/$PRFX.stake.vkey \
    --cold-verification-key-file $CRVLM_COLD/$PRFX.cold.vkey \
    --out-file $CRVLM_COLD/$PRFX.stake-delegation.cert

echo "Copy deleg.cert to your hot environment."
cp -v $CRVLM_COLD/$PRFX.stake-delegation.cert $POOL

currentSlot=$(cardano-cli query tip --mainnet | jq -r '.slot')
echo Current Slot: $currentSlot

echo "Find your balance and UTXOs."
cardano-cli query utxo --address $(cat $POOL/$PRFX.payment.addr) --mainnet > $POOL/fullUtxo.out
tail -n +3 $POOL/fullUtxo.out | sort -k3 -nr > $POOL/balance.out
cat $POOL/balance.out
tx_in=""
total_balance=0
while read -r utxo; do
    in_addr=$(awk '{ print $1 }' <<< "${utxo}")
    idx=$(awk '{ print $2 }' <<< "${utxo}")
    utxo_balance=$(awk '{ print $3 }' <<< "${utxo}")
    total_balance=$((${total_balance}+${utxo_balance}))
    echo TxHash: ${in_addr}#${idx}
    echo ADA: ${utxo_balance}
    tx_in="${tx_in} --tx-in ${in_addr}#${idx}"
done < $POOL/balance.out
txcnt=$(cat $POOL/balance.out | wc -l)
echo Total ADA balance: ${total_balance}
echo Number of UTXOs: ${txcnt}

echo "Find the deposit fee for a pool."
cardano-cli query protocol-parameters --mainnet --out-file=$NODE_HOME/params.json

echo "Find the minimum pool cost."
minPoolCost=$(cat $NODE_HOME/params.json | jq -r .minPoolCost)
echo minPoolCost: ${minPoolCost}
#echo "minPoolCost is 340000000 lovelace or 340 ADA. Therefore, your --pool-cost must be at a minimum this amount."

stakePoolDeposit=$(cat $NODE_HOME/params.json | jq -r '.stakePoolDeposit')
echo stakePoolDeposit : $stakePoolDeposit

echo "Run the build-raw transaction command."
cardano-cli transaction build-raw \
    ${tx_in} \
    --tx-out $(cat $POOL/$PRFX.payment.addr)+$(( ${total_balance} - ${stakePoolDeposit} ))  \
    --invalid-hereafter $(( ${currentSlot} + 10000)) \
    --fee 0 \
    --certificate-file $POOL/$PRFX.pool-registration.cert \
    --certificate-file $POOL/$PRFX.stake-delegation.cert \
    --out-file $POOL/$PRFX.tx.pool.tmp

echo "Calculate the minimum fee:"
fee=$(cardano-cli transaction calculate-min-fee \
    --tx-body-file $POOL/$PRFX.tx.pool.tmp \
    --tx-in-count ${txcnt} \
    --tx-out-count 1 \
    --mainnet \
    --witness-count 3 \
    --byron-witness-count 0 \
    --protocol-params-file $NODE_HOME/params.json | awk '{ print $1 }')
echo fee: $fee

#Ensure your balance is greater than cost of fee + minPoolCost or this will not work.
txOut=$((${total_balance}-${stakePoolDeposit}-${fee}))
echo txOut: ${txOut}

echo "Build the transaction."
cardano-cli transaction build-raw \
    ${tx_in} \
    --tx-out $(cat $POOL/$PRFX.payment.addr)+${txOut} \
    --invalid-hereafter $(( ${currentSlot} + 10000)) \
    --fee ${fee} \
    --certificate-file $POOL/$PRFX.pool-registration.cert \
    --certificate-file $POOL/$PRFX.stake-delegation.cert \
    --out-file $POOL/$PRFX.tx.pool.raw

echo "Copy tx.raw to your cold environment."
cp -fv $POOL/$PRFX.tx.pool.raw $CRVLM_COLD

echo "Sign the transaction."
cardano-cli transaction sign \
    --tx-body-file $CRVLM_COLD/$PRFX.tx.pool.raw \
    --signing-key-file $CRVLM_COLD/$PRFX.payment.skey \
    --signing-key-file $CRVLM_COLD/$PRFX.cold.skey \
    --signing-key-file $CRVLM_COLD/$PRFX.stake.skey \
    --mainnet \
    --out-file $CRVLM_COLD/$PRFX.tx.pool.signed

echo "Copy tx.signed to your hot environment."
cp -fv $CRVLM_COLD/$PRFX.tx.pool.signed $POOL

echo "Send the transaction."
cardano-cli transaction submit --tx-file $POOL/$PRFX.tx.pool.signed --mainnet

echo Remove temp files
rm -fv $POOL/$PRFX.tx.pool.tmp
rm -fv $POOL/fullUtxo.out
rm -fv $POOL/balance.out
