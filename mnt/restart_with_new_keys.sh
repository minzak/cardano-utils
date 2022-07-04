#https://www.coincashew.com/coins/overview-ada/guide-how-to-build-a-haskell-stakepool-node/part-iv-administration/rotating-kes-keys

PRFX=node2
NODE_HOME=/opt/cardano
POOL=/opt/cardano/pool-keys
NEW=/opt/cardano/new-keys

echo "you must to check when we can restart node with new keys, binary, etc. by running ./verify_schedule.sh"
#./verify_shedule.sh

mv -vf $NEW/$PRFX.kes.skey $POOL
mv -vf $NEW/$PRFX.kes.vkey $POOL
mv -vf $NEW/$PRFX.op.cert $POOL
echo "Restarting Cardano with new keys"
systemctl restart cardano-core.service

