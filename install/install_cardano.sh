apt-get update -y
apt-get upgrade -y
apt-get install sudo mc htop wget -y

cd /usr/local/src
git clone https://github.com/input-output-hk/libsodium
cd libsodium
git checkout 66f017f1
./autogen.sh
./configure
make
sudo make install

#Install Cabal and dependencies.
sudo apt-get -y install pkg-config libgmp-dev libssl-dev libtinfo-dev libsystemd-dev zlib1g-dev build-essential curl libgmp-dev libffi-dev libncurses-dev libtinfo5
curl --proto '=https' --tlsv1.2 -sSf https://get-ghcup.haskell.org | sh

cd $HOME
source .bashrc
ghcup upgrade
ghcup install cabal 3.4.0.0
ghcup set cabal 3.4.0.0

ghcup install ghc 8.10.4
ghcup set ghc 8.10.4

echo >> ~/.bashrc
echo "PATH=\$PATH:/.local/bin:/root/.cabal/bin:/root/.ghcup/bin" >> ~/.bashrc
echo "export LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH" >> ~/.bashrc
echo "export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig:$PKG_CONFIG_PATH" >> ~/.bashrc
echo "export NODE_HOME=/opt/cardano/" >> ~/.bashrc
echo "export NODE_CONFIG=mainnet" >> ~/.bashrc
source ~/.bashrc

cabal update
cabal --version
ghc --version


cd /usr/local/src/
git clone https://github.com/input-output-hk/cardano-node.git
cd cardano-node
git fetch --all --recurse-submodules --tags
git checkout $(curl -s https://api.github.com/repos/input-output-hk/cardano-node/releases/latest | grep -oP '"tag_name": "\K(.*)(?=")')
cabal configure -O0 -w ghc-8.10.4
echo -e "package cardano-crypto-praos\n flags: -external-libsodium-vrf" > cabal.project.local
sed -i $HOME/.cabal/config -e "s/overwrite-policy:/overwrite-policy: always/g"
rm -rf $HOME/git/cardano-node/dist-newstyle/build/x86_64-linux/ghc-8.10.4
cabal build all


mkdir -p /opt/cardano/
cp -p $(find /usr/local/src/cardano-node/dist-newstyle/build/ -type f -name "cardano-topology") /opt/cardano/
cp -p $(find /usr/local/src/cardano-node/dist-newstyle/build/ -type f -name "cardano-node") /opt/cardano/
cp -p $(find /usr/local/src/cardano-node/dist-newstyle/build/ -type f -name "cardano-cli") /opt/cardano/
source ~/.bashrc

sudo ln -s /opt/cardano/cardano-cli /usr/local/bin/cardano-cli
sudo ln -s /opt/cardano/cardano-node /usr/local/bin/cardano-node

cardano-node version
cardano-cli version
