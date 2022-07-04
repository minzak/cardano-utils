#cat <<EOF > ~/.common.inc
offlineMode="no"

socket="/opt/cardano/node-core/db/node.socket"

genesisfile="/opt/cardano/node-core/mainnet-shelley-genesis.json"           #Shelley-Genesis path
genesisfile_byron="/opt/cardano/node-core/mainnet-byron-genesis.json"       #Byron-Genesis path

cardanocli="cardano-cli"        #Path to your cardano-cli you wanna use
cardanonode="cardano-node"      #Path to your cardano-node you wanna use

magicparam="--mainnet"  #choose "--mainnet" for mainnet or for example "--testnet-magic 1097911063" for a testnet
addrformat="--mainnet"  #choose "--mainnet" for mainnet address format or like "--testnet-magic 1097911063" for testnet address format

itn_jcli="./jcli" #only needed if you wanna include your itn witness for your pool-ticker

#--------- leave this next value until you have to change it for a testnet
byronToShelleyEpochs=208 #208 for the mainnet, 74 for the testnet
#EOF
