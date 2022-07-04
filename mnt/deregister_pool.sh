#https://cardano-foundation.gitbook.io/stake-pool-course/stake-pool-guide/stake-pool/retire_stakepool

PRFX=node2
NODE_HOME=/opt/cardano
POOL=/opt/cardano/pool-keys
CRVLM_COLD=/opt/cardano/cold-keys

echo "Finding current epoch."
epoch=$(cardano-cli query tip --mainnet | jq -r .epoch)
echo Current epoch: ${epoch}

echo "Create the deregistration certificate."
cardano-cli stake-pool deregistration-certificate \
--cold-verification-key-file $CRVLM_COLD/$PRFX.cold.vkey \
--epoch $((${epoch} + 1)) \
--out-file $POOL/$PRFX.pool-deregistration.cert


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

cardano-cli query protocol-parameters --mainnet --out-file=$NODE_HOME/params.json

echo "Build the transaction template for fee."
cardano-cli transaction build-raw \
    ${tx_in} \
    --tx-out $(cat $POOL/$PRFX.payment.addr)+0 \
    --invalid-hereafter $(( ${currentSlot} + 10000)) \
    --fee 0 \
    --certificate-file $POOL/$PRFX.pool-deregistration.cert \
    --out-file $POOL/$PRFX.tx.dereg.tmp

echo "Calculate the minimum fee:"
fee=$(cardano-cli transaction calculate-min-fee \
    --tx-body-file $POOL/$PRFX.tx.dereg.tmp \
    --tx-in-count ${txcnt} \
    --tx-out-count 1 \
    --mainnet \
    --witness-count 1 \
    --byron-witness-count 0 \
    --protocol-params-file $NODE_HOME/params.json | awk '{ print $1 }')
echo fee: $fee

txOut=$((${total_balance}-${fee}))
echo txOut: ${txOut}

echo "Build the transaction."
cardano-cli transaction build-raw \
    ${tx_in} \
    --tx-out $(cat $POOL/$PRFX.payment.addr)+${txOut} \
    --invalid-hereafter $(( ${currentSlot} + 10000)) \
    --fee ${fee} \
    --certificate-file $POOL/$PRFX.pool-deregistration.cert \
    --out-file $POOL/$PRFX.tx.dereg.raw

echo "Copy tx.raw to your cold environment."
cp -fv $POOL/$PRFX.tx.dereg.raw $CRVLM_COLD

echo "Sign the transaction."
cardano-cli transaction sign \
    --tx-body-file $CRVLM_COLD/$PRFX.tx.dereg.raw \
    --signing-key-file $CRVLM_COLD/$PRFX.cold.skey \
    --signing-key-file $CRVLM_COLD/$PRFX.payment.skey \
    --mainnet \
    --out-file $CRVLM_COLD/$PRFX.tx.dereg.signed

echo "Copy tx.signed to your hot environment."
cp -fv $CRVLM_COLD/$PRFX.tx.dereg.signed $POOL

echo "Send the transaction."
cardano-cli transaction submit --tx-file $POOL/$PRFX.tx.dereg.signed --mainnet

echo Remove temp files
rm -fv $POOL/fullUtxo.out
rm -fv $POOL/balance.out
rm -fv $POOL/$PRFX.tx.dereg.tmp
