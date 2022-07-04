#https://github.com/input-output-hk/cardano-node/blob/master/doc/stake-pool-operations/withdraw-rewards.md

PRFX=node2
NODE_HOME=/opt/cardano
POOL=/opt/cardano/pool-keys
CRVLM_COLD=/opt/cardano/cold-keys

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
echo TX_in: ${tx_in}

echo "Check the balance of the rewards address: $(cat $POOL/$PRFX.stake.addr)"
reward=$( cardano-cli query stake-address-info --mainnet --address $(cat $POOL/$PRFX.stake.addr) | jq .[].rewardAccountBalance )
echo $reward

echo "Check balance $(cat $POOL/$PRFX.send2.addr)"
cardano-cli query stake-address-info --mainnet --address $(cat $POOL/$PRFX.send2.addr)

echo "Build the transaction template for fee."
cardano-cli transaction build-raw \
    ${tx_in} \
    --tx-out $(cat $POOL/$PRFX.send2.addr)+0 \
    --withdrawal $(cat $POOL/$PRFX.stake.addr)+0 \
    --invalid-hereafter 0 \
    --fee 0 \
    --out-file $POOL/withdraw_rewards.draft

echo "Calculate the minimum fee:"
cardano-cli query protocol-parameters --mainnet --out-file=$NODE_HOME/params.json
fee=$(cardano-cli transaction calculate-min-fee \
    --tx-body-file $POOL/withdraw_rewards.draft \
    --tx-in-count ${txcnt} \
    --tx-out-count 1 \
    --mainnet \
    --witness-count 1 \
    --byron-witness-count 0 \
    --protocol-params-file $NODE_HOME/params.json | awk '{ print $1 }')
echo fee: $fee

#26 ADA >= Committed Pledge = 25 ADA !!! for Active Pledge.
txOut=$((${total_balance}-${fee}+${reward}-26000000))
echo txOut: ${txOut}

echo "Build the transaction."
cardano-cli transaction build-raw \
    ${tx_in} \
    --tx-out $(cat $POOL/$PRFX.send2.addr)+${txOut} \
    --withdrawal $(cat $POOL/$PRFX.stake.addr)+${reward} \
    --invalid-hereafter $(( ${currentSlot} + 500)) \
    --fee ${fee} \
    --out-file $POOL/withdraw_rewards.raw

echo "Sign the transaction."
cardano-cli transaction sign \
    --tx-body-file $POOL/withdraw_rewards.raw \
    --signing-key-file $CRVLM_COLD/$PRFX.stake.skey \
    --mainnet \
    --out-file $POOL/withdraw_rewards.signed

#    --signing-key-file $CRVLM_COLD/$PRFX.payment.skey \

echo "Send the transaction."
cardano-cli transaction submit --tx-file $POOL/withdraw_rewards.signed --mainnet

echo Remove temp files
rm -fv $POOL/fullUtxo.out
rm -fv $POOL/balance.out
rm -fv $POOL/withdraw_rewards.draft
