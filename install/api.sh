#cardano-cli query tip --mainnet

#curl -s -m 3 -H 'Accept: application/json' http://127.0.0.1:12788/ | jq '.cardano.node.metrics.epoch.int.val'

Q=$(curl -s -m 3 -H 'Accept: application/json' http://127.0.0.1:12788/ | jq '.cardano.node.metrics')


echo "operationalCertificateStartKESPeriod" & echo $Q | jq .operationalCertificateStartKESPeriod.int.val
echo "currentKESPeriod" & echo $Q | jq .currentKESPeriod.int.val
echo "remainingKESPeriods" & echo $Q | jq .remainingKESPeriods.int.val
echo "epoch" & echo $Q | jq .epoch.int.val

