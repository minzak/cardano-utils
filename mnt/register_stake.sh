#https://www.coincashew.com/coins/overview-ada/guide-how-to-build-a-haskell-stakepool-node/part-iii-operation/registering-your-stake-address

#Cryptovolumes must be mounted
#/mnt/crypt_mount_cold_vlm.sh

PRFX=node2
NODE_HOME=/opt/cardano
POOL=/opt/cardano/pool-keys
CRVLM_COLD=/opt/cardano/cold-keys

#To register a stake address on the blockchain: Create a certificate, stake.cert, using the stake.vkey
cardano-cli stake-address registration-certificate --stake-verification-key-file=$CRVLM_COLD/$PRFX.stake.vkey --out-file=$CRVLM_COLD/$PRFX.stake.cert
cp -fv $CRVLM_COLD/$PRFX.stake.cert $POOL

cd $POOL
#You need to find the tip of the blockchain to set the invalid-hereafter parameter properly.
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

#Find the amount of the deposit required to register a stake address.
cardano-cli query protocol-parameters --mainnet --out-file=$NODE_HOME/params.json
stakeAddressDeposit=$(cat $NODE_HOME/params.json | jq -r '.stakeAddressDeposit')
echo stakeAddressDeposit : $stakeAddressDeposit

#Registering a stake address requires a deposit of 2000000 lovelace. 2 ADA
#The invalid-hereafter value must be greater than the current tip. In this example, we use current slot + 10000.
cardano-cli transaction build-raw \
    ${tx_in} \
    --tx-out $(cat $POOL/$PRFX.payment.addr)+1500000 \
    --invalid-hereafter $(( ${currentSlot} + 10000)) \
    --fee 0 \
    --out-file $POOL/$PRFX.tx.stake.tmp \
    --certificate $POOL/$PRFX.stake.cert

echo "Calculate the current minimum fee:"
fee=$(cardano-cli transaction calculate-min-fee \
    --tx-body-file $POOL/$PRFX.tx.stake.tmp \
    --tx-in-count ${txcnt} \
    --tx-out-count 1 \
    --mainnet \
    --witness-count 2 \
    --byron-witness-count 0 \
    --protocol-params-file $NODE_HOME/params.json | awk '{ print $1 }')
echo fee: $fee

#Calculate your change output.
txOut=$((${total_balance}-${stakeAddressDeposit}-${fee}))
echo Change Output: ${txOut}

echo "Build your transaction which will register your stake address."
cardano-cli transaction build-raw \
    ${tx_in} \
    --tx-out $(cat $POOL/$PRFX.payment.addr)+${txOut} \
    --invalid-hereafter $(( ${currentSlot} + 10000)) \
    --fee ${fee} \
    --certificate-file $POOL/$PRFX.stake.cert \
    --out-file $POOL/$PRFX.tx.stake.raw

echo "Copy tx.raw to your cold environment."
cp -fv $POOL/$PRFX.tx.stake.raw $CRVLM_COLD

echo "Sign the transaction with both the payment and stake secret keys."
cardano-cli transaction sign \
    --tx-body-file $CRVLM_COLD/$PRFX.tx.stake.raw \
    --signing-key-file $CRVLM_COLD/$PRFX.payment.skey \
    --signing-key-file $CRVLM_COLD/$PRFX.stake.skey \
    --mainnet \
    --out-file $CRVLM_COLD/$PRFX.tx.stake.signed

echo "Copy tx.signed to your hot environment."
cp -fv $CRVLM_COLD/$PRFX.tx.stake.signed $POOL

echo "Send the signed transaction."
cardano-cli transaction submit --tx-file $POOL/$PRFX.tx.stake.signed --mainnet

echo Remove temp files:
rm -vf $POOL/$PRFX.tx.stake.tmp
rm -vf $POOL/fullUtxo.out
rm -vf $POOL/balance.out
