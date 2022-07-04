#COLD VOLUME INIT

PRFX=node2
CRVLM='/mnt/crypt/crypt_cold_'$PRFX'.img'
CRVLM_NAME='crypt_cold_'$PRFX
CRVLM_PATH=/opt/cardano/cold-keys
POOL=/opt/cardano/pool-keys

dd if=/dev/zero of=$CRVLM bs=1024 count=102400
cryptsetup -q luksFormat -c aes-xts-plain64 -s 256 -h sha256 $CRVLM

cryptsetup -q luksOpen $CRVLM $CRVLM_NAME
mkfs.ext4 /dev/mapper/$CRVLM_NAME

mount /dev/mapper/$CRVLM_NAME $CRVLM_PATH
touch $CRVLM_PATH/crypto-$PRFX-cold-volume

#https://github.com/input-output-hk/cardano-node/blob/master/doc/stake-pool-operations/keys_and_addresses.md

cd $POOL
#Generate the KES Key pair:
cardano-cli node key-gen-KES --verification-key-file=$POOL/$PRFX.kes.vkey --signing-key-file=$POOL/$PRFX.kes.skey
#Generate VRF Key pair
cardano-cli node key-gen-VRF --verification-key-file=$POOL/$PRFX.vrf.vkey --signing-key-file=$POOL/$PRFX.vrf.skey
chmod 400 $PRFX.*.skey
chmod 400 $PRFX.*.vkey

#You must also copy vrf.vkey and kes.vkey to your cold environment.
cp -f $POOL/$PRFX.*.vkey $CRVLM_PATH

cd $CRVLM_PATH
#To generate a stake key pair:
cardano-cli stake-address key-gen --verification-key-file $PRFX.stake.vkey --signing-key-file $PRFX.stake.skey
echo Private Stake key:
cat $PRFX.stake.skey | jq
echo Public Stake key
cat $PRFX.stake.vkey | jq
#Generate a payment key pair: payment.vkey (the public verification key) and payment.skey (the private signing key)
cardano-cli address key-gen --verification-key-file $PRFX.payment.vkey --signing-key-file $PRFX.payment.skey
echo Private Payment key:
cat $PRFX.payment.skey | jq
echo Public Payment key
cat $PRFX.payment.vkey | jq
#To generate a stake address: This address CAN'T receive payments but will receive the rewards from participating in the protocol.
cardano-cli stake-address build --stake-verification-key-file=$PRFX.stake.vkey --out-file=$PRFX.stake.addr --mainnet
echo Stake address: $(cat $PRFX.stake.addr)
#Payment address. Both verification keys (payment.vkey and stake.vkey) are used to build the address and the resulting payment address is associated with these keys.
cardano-cli address build --payment-verification-key-file=$PRFX.payment.vkey --stake-verification-key-file=$PRFX.stake.vkey --out-file=$PRFX.payment.addr --mainnet
echo Payment address: $(cat $PRFX.payment.addr)
#Generate Cold Keys and a Cold_counter file:
cardano-cli node key-gen --cold-verification-key-file=$PRFX.cold.vkey --cold-signing-key-file=$PRFX.cold.skey --operational-certificate-issue-counter=$PRFX.cold.counter
chmod 400 $PRFX.*.addr
chmod 400 $PRFX.*.vkey
chmod 400 $PRFX.*.skey
chmod 400 $PRFX.*.counter
cp -f $CRVLM_PATH/$PRFX.*.addr $POOL
cp -f $CRVLM_PATH/$PRFX.*.vkey $POOL

echo "Your stake pool ID can be computed"
cardano-cli stake-pool id --cold-verification-key-file $POOL/$PRFX.cold.vkey --output-format "hex" > $POOL/$PRFX.stakepoolid.txt
cardano-cli stake-pool id --cold-verification-key-file $POOL/$PRFX.cold.vkey --output-format "bech32" >> $POOL/$PRFX.stakepoolid.txt
cat $POOL/$PRFX.stakepoolid.txt
echo "Copy stakepoolid.txt to your hot environment."
cp -fv $POOL/$PRFX.stakepoolid.txt $CRVLM_PATH

#get the slots per KES period from the genesis file:
echo slots per KES period:
cat /opt/cardano/node-core/mainnet-shelley-genesis.json | jq -r .slotsPerKESPeriod
#the current tip of the blockchain:
echo current tip:
cardano-cli query tip --mainnet | jq -r .slot
#So we have KES period is:
echo KES period:
echo $(($(cardano-cli query tip --mainnet | jq -r .slot) / $(cat /opt/cardano/node-core/mainnet-shelley-genesis.json | jq -r .slotsPerKESPeriod )))
#Now, you can generate the operational certificate:
cardano-cli node issue-op-cert --kes-verification-key-file=$PRFX.kes.vkey --cold-signing-key-file=$PRFX.cold.skey --operational-certificate-issue-counter=$PRFX.cold.counter --out-file=$PRFX.op.cert \
--kes-period $(($(cardano-cli query tip --mainnet | jq -r .slot) / $(cat /opt/cardano/node-core/mainnet-shelley-genesis.json | jq -r .slotsPerKESPeriod )))
chmod 400 $PRFX.op.cert
cp -f $PRFX.op.cert $POOL


ls -latrh $CRVLM_PATH
cd ~
umount $CRVLM_PATH
cryptsetup close $CRVLM_NAME
