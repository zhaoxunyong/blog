---
title: Fabric Getting Started
date: 2022-06-08 11:33:18
categories: ["Linux"]
tags: ["Linux","BlockChain"]
toc: true
---

A getting started guilde to Fabric. Following https://hyperledger-fabric.readthedocs.io/en/latest/whatis.html to what it is.

<!-- more -->

# Installation

Using Vagant and docker as a platform to try.

The detailed instructions refer to: https://github.com/zhaoxunyong/boxes/tree/main/docker/fabric 

## Startup

```bash
Step 1:
cd /data/vagrant/docker
vagrant destroy node1 -f
rm -fr /data/var-lib-docker/
vagrant up node1

#Entering the container:
#vagrant docker-exec -it node1 -- /bin/bash
#docker exec -it `docker ps|grep node1|awk '{print $1}'` /vagrant/changepwd.sh
docker exec -it `docker ps|grep node1|awk '{print $1}'` /vagrant/images/importImages.sh
vagrant reload node1
#Then login with terminal, not docker exec
#docker restart `docker ps|grep node1|awk '{print $1}'`
```

# Starting a chaincode on the channel

```
#https://hyperledger-fabric.readthedocs.io/en/latest/test_network.html
#Openning a new terminal to input the following command:
cd /data/fabric/fabric-samples/test-network
./network.sh up 
#Creating a channel
./network.sh createChannel
#./network.sh up createChannel
#Monitor:
./monitordocker.sh fabric_test

#The following instruction need GO to be installed.
./network.sh deployCC -ccn basic -ccp ../asset-transfer-basic/chaincode-go -ccl go

#The following instruction need node.js to be installed.
./network.sh deployCC -ccn basic -ccp ../asset-transfer-basic/chaincode-javascript -ccl javascript

#The following instruction need java to be installed.
# Not need:
# #Setting the proxy to download gradle-7.3.1-bin.zip. Or downloading maybe is very slow...
# tee /data/fabric/fabric-samples/asset-transfer-basic/chaincode-java/gradle.properties <<-'EOF'
# systemProp.http.proxyHost=192.168.102.82
# systemProp.http.proxyPort=1082
# systemProp.https.proxyHost=192.168.102.82
# systemProp.https.proxyPort=1082
# systemProp.http.nonProxyHosts=192.*|172.*|127.*|localhost
# EOF
./network.sh deployCC -ccn basic -ccp ../asset-transfer-basic/chaincode-java -ccl java
#Don't use the proxy to build, Or you will encouter the following errors:
Error: chaincode install failed with status: 500 - error in simulation: failed to execute transaction c6d2553ed5f14fa4336438c686f538730f90f51bf1c5737f60c0cd3f0e17561a: error sending: timeout expired while executing transaction
```

# Interacting with the network

```
cd /data/fabric/fabric-samples/test-network
export PATH=${PWD}/../bin:$PATH
export FABRIC_CFG_PATH=$PWD/../config/

#You can now set the environment variables that allow you to operate the peer CLI as Org1:
#Environment variables for Org1
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_LOCALMSPID="Org1MSP"
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
export CORE_PEER_ADDRESS=localhost:7051

#Run the following command to initialize the ledger with assets.
peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem" -C mychannel -n basic --peerAddresses localhost:7051 --tlsRootCertFiles "${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt" --peerAddresses localhost:9051 --tlsRootCertFiles "${PWD}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt" -c '{"function":"InitLedger","Args":[]}'

#You can now query the ledger from your CLI. Run the following command to get the list of assets that were added to your channel ledger:
peer chaincode query -C mychannel -n basic -c '{"Args":["GetAllAssets"]}' | prettyjson

#Use the following command to change the owner of an asset on the ledger by invoking the asset-transfer (basic) chaincode:
peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem" -C mychannel -n basic --peerAddresses localhost:7051 --tlsRootCertFiles "${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt" --peerAddresses localhost:9051 --tlsRootCertFiles "${PWD}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt" -c '{"function":"TransferAsset","Args":["asset6","Christopher"]}'

#Set the following environment variables to operate as Org2:
#Environment variables for Org2
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_LOCALMSPID="Org2MSP"
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp
export CORE_PEER_ADDRESS=localhost:9051

#You can now query the asset-transfer (basic) chaincode running on peer0.org2.example.com:
peer chaincode query -C mychannel -n basic -c '{"Args":["ReadAsset","asset6"]}'

#Bring down the network
./network.sh down
#relogin to take effect from trying again.
<!-- docker rm -f $(docker ps -aq)
docker rmi -f $(docker images -q)
docker rmi -f $(docker images | grep dev-peer[0-9] | awk '{print $3}') -->
```

# Deploying a smart contract to a channel

## Package the smart contract
```
#GO
cd /data/fabric/fabric-samples/test-network
export PATH=${PWD}/../bin:$PATH
export FABRIC_CFG_PATH=$PWD/../config/
peer version
#You can now create the chaincode package using the peer lifecycle chaincode package command:
peer lifecycle chaincode package basic.tar.gz --path ../asset-transfer-basic/chaincode-go/ --lang golang --label basic_1.0
```

## Install the chaincode package
```
both Org1 and org2

#We can now install the chaincode on the Org1 peer
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_LOCALMSPID="Org1MSP"
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
export CORE_PEER_ADDRESS=localhost:7051

peer lifecycle chaincode install basic.tar.gz

#We can now install the chaincode on the Org2 peer
export CORE_PEER_LOCALMSPID="Org2MSP"
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp
export CORE_PEER_ADDRESS=localhost:9051

peer lifecycle chaincode install basic.tar.gz
```

## Approve a chaincode definition
```
both Org1 and org2

#You can find the package ID of a chaincode by using the peer lifecycle chaincode queryinstalled command to query your peer
peer lifecycle chaincode queryinstalled

#let’s go ahead and save it as an environment variable. Paste the package ID returned by peer lifecycle chaincode queryinstalled into the command below
export CC_PACKAGE_ID=basic_1.0:2e20ce421c8037420718c8a3918a1eea76343b7361fffdac454181c54e5736c7

#Chaincode is approved at the organization level, so the command only needs to target one peer. The approval is distributed to the other peers within the organization using gossip. Approve the chaincode definition using the peer lifecycle chaincode approveformyorg command:

peer lifecycle chaincode approveformyorg -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --channelID mychannel --name basic --version 1.0 --package-id $CC_PACKAGE_ID --sequence 1 --tls --cafile "${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem"


#We still need to approve the chaincode definition as Org1
export CORE_PEER_LOCALMSPID="Org1MSP"
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
export CORE_PEER_ADDRESS=localhost:7051

peer lifecycle chaincode approveformyorg -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --channelID mychannel --name basic --version 1.0 --package-id $CC_PACKAGE_ID --sequence 1 --tls --cafile "${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem"

#We now have the majority we need to deploy the asset-transfer (basic) the chaincode to the channel. 
```

## Committing the chaincode definition to the channel
```
"peer lifecycle chaincode commit" need to imply the both of peers of Org1 and Org2:
--peerAddresses localhost:7051
--peerAddresses localhost:9051 


#After a sufficient number of organizations have approved a chaincode definition, one organization can commit the chaincode definition to the channel
You can use the peer lifecycle chaincode checkcommitreadiness command to check whether channel members have approved the same chaincode definition

peer lifecycle chaincode checkcommitreadiness --channelID mychannel --name basic --version 1.0 --sequence 1 --tls --cafile "${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem" --output json

#You can use the peer lifecycle chaincode commit command to commit the chaincode definition to the channel. The commit command also needs to be submitted by an organization admin.

peer lifecycle chaincode commit -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --channelID mychannel --name basic --version 1.0 --sequence 1 --tls --cafile "${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem" --peerAddresses localhost:7051 --tlsRootCertFiles "${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt" --peerAddresses localhost:9051 --tlsRootCertFiles "${PWD}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt"

#You can use the peer lifecycle chaincode querycommitted command to confirm that the chaincode definition has been committed to the channel.

peer lifecycle chaincode querycommitted --channelID mychannel --name basic --cafile "${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem"
```

## Invoking the chaincode
```
#Use the following command to create an initial set of assets on the ledger. Note the CLI does not access the Fabric Gateway peer, so each endorsing peer must be specified.

peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem" -C mychannel -n basic --peerAddresses localhost:7051 --tlsRootCertFiles "${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt" --peerAddresses localhost:9051 --tlsRootCertFiles "${PWD}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt" -c '{"function":"InitLedger","Args":[]}'

#We can use a query function to read the set of cars that were created by the chaincode:

peer chaincode query -C mychannel -n basic -c '{"Args":["GetAllAssets"]}' | prettyjson
```

## Upgrading a smart contract
```
#Openning a new terminal to input the following command:
cd /data/fabric/fabric-samples/asset-transfer-basic/chaincode-javascript
npm install
cd ../../test-network
export PATH=${PWD}/../bin:$PATH
export FABRIC_CFG_PATH=$PWD/../config/

#You can then issue the following commands to package the JavaScript chaincode from the test-network directory. We will set the environment variables needed to use the peer CLI again in case you closed your terminal.

export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
peer lifecycle chaincode package basic_2.tar.gz --path ../asset-transfer-basic/chaincode-javascript/ --lang node --label basic_2.0

#Run the following commands to operate the peer CLI as the Org1 admin:

export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_LOCALMSPID="Org1MSP"
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
export CORE_PEER_ADDRESS=localhost:7051

#https://charlielin.top/2020/03/26/%E5%9C%A8-fabric-%E4%B8%8A%E6%89%A7%E8%A1%8C-chaincode-%E7%9A%84%E6%A2%B3%E7%90%86/
#We can now use the following command to install the new chaincode package on the Org1 peer.
#It much more slower than installing go, which needs a few seconds to be installed, just wait with patient:
peer lifecycle chaincode install basic_2.tar.gz
peer lifecycle chaincode queryinstalled

#ou can use the package label to find the package ID of the new chaincode and save it as a new environment variable. This output is for example only – your package ID will be different, so DO NOT COPY AND PASTE!
export NEW_CC_PACKAGE_ID=basic_2.0:65dc35f2a2bfc653fc329254b5e0ab2646b4fd65f7613f7772d9954da064a224

#Org1 can now approve a new chaincode definition:
#Because the sequence parameter is used by the Fabric chaincode lifecycle to keep track of chaincode upgrades, Org1 also needs to increment the sequence number from 1 to 2
peer lifecycle chaincode approveformyorg -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --channelID mychannel --name basic --version 2.0 --package-id $NEW_CC_PACKAGE_ID --sequence 2 --tls --cafile "${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem"


#We now need to install the chaincode package and approve the chaincode definition as Org2 in order to upgrade the chaincode. 

export CORE_PEER_LOCALMSPID="Org2MSP"
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp
export CORE_PEER_ADDRESS=localhost:9051

#We can now use the following command to install the new chaincode package on the Org2 peer.
peer lifecycle chaincode install basic_2.tar.gz

#You can now approve the new chaincode definition for Org2.

peer lifecycle chaincode approveformyorg -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --channelID mychannel --name basic --version 2.0 --package-id $NEW_CC_PACKAGE_ID --sequence 2 --tls --cafile "${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem"

#check if the chaincode definition with sequence 2 is ready to be committed to the channel:

peer lifecycle chaincode checkcommitreadiness --channelID mychannel --name basic --version 2.0 --sequence 2 --tls --cafile "${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem" --output json

#Org2 can use the following command to upgrade the chaincode:

peer lifecycle chaincode commit -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --channelID mychannel --name basic --version 2.0 --sequence 2 --tls --cafile "${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem" --peerAddresses localhost:7051 --tlsRootCertFiles "${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt" --peerAddresses localhost:9051 --tlsRootCertFiles "${PWD}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt"


#we can test our new JavaScript chaincode by creating a new car:

peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem" -C mychannel -n basic --peerAddresses localhost:7051 --tlsRootCertFiles "${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt" --peerAddresses localhost:9051 --tlsRootCertFiles "${PWD}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt" -c '{"function":"CreateAsset","Args":["asset8","blue","16","Kelley","750"]}'


#Clean up

docker stop logspout
docker rm logspout
cd /data/fabric/fabric-samples/test-network
./network.sh down
```

# Running a Fabric Application

## Set up the blockchain network

./network.sh up createChannel -c mychannel -ca


## Deploy the smart contract

./network.sh deployCC -ccn basic -ccp ../asset-transfer-basic/chaincode-typescript/ -ccl typescript


## Prepare the sample application
```
cd ../asset-transfer-basic/application-gateway-typescript
apt install -y make g++
npm install
npm run-script build
npm start
```

# Running chaincode in development mode

## Set up environment
```
#git clone https://github.com/hyperledger/fabric
apt install -y make g++
cp -a /vagrant/fabric /Developer/
cd /Developer/fabric
make orderer peer configtxgen

export PATH=$(pwd)/build/bin:$PATH
export FABRIC_CFG_PATH=$(pwd)/sampleconfig
sudo mkdir /var/hyperledger
configtxgen -profile SampleDevModeSolo -channelID syschannel -outputBlock genesisblock -configPath $FABRIC_CFG_PATH -outputBlock "$(pwd)/sampleconfig/genesisblock"
```

## Start the orderer

ORDERER_GENERAL_GENESISPROFILE=SampleDevModeSolo orderer

## Start the peer in DevMode
```
#Open another terminal window and set the required environment variables to override the peer configuration and start the peer node:
cd /Developer/fabric
export CORE_OPERATIONS_LISTENADDRESS=127.0.0.1:9444
export PATH=$(pwd)/build/bin:$PATH
export FABRIC_CFG_PATH=$(pwd)/sampleconfig
FABRIC_LOGGING_SPEC=chaincode=debug CORE_PEER_CHAINCODELISTENADDRESS=0.0.0.0:7052 peer node start --peer-chaincodedev=true
```

## Create channel and join peer
```
#Open another terminal window

cd /Developer/fabric
export PATH=$(pwd)/build/bin:$PATH
export FABRIC_CFG_PATH=$(pwd)/sampleconfig
configtxgen -channelID ch1 -outputCreateChannelTx ch1.tx -profile SampleSingleMSPChannel -configPath $FABRIC_CFG_PATH
peer channel create -o 127.0.0.1:7050 -c ch1 -f ch1.tx
peer channel join -b ch1.block
```

## Build the chaincode
```
cd /Developer/fabric
go build -o simpleChaincode ./integration/chaincode/simple/cmd
```

## Start the chaincode

CORE_CHAINCODE_LOGLEVEL=debug CORE_PEER_TLS_ENABLED=false CORE_CHAINCODE_ID_NAME=mycc:1.0 ./simpleChaincode -peer.address 127.0.0.1:7052


## Approve and commit the chaincode definition
```
#Open another terminal window

cd /Developer/fabric
export PATH=$(pwd)/build/bin:$PATH
export FABRIC_CFG_PATH=$(pwd)/sampleconfig
peer lifecycle chaincode approveformyorg  -o 127.0.0.1:7050 --channelID ch1 --name mycc --version 1.0 --sequence 1 --init-required --signature-policy "OR ('SampleOrg.member')" --package-id mycc:1.0
peer lifecycle chaincode checkcommitreadiness -o 127.0.0.1:7050 --channelID ch1 --name mycc --version 1.0 --sequence 1 --init-required --signature-policy "OR ('SampleOrg.member')"
peer lifecycle chaincode commit -o 127.0.0.1:7050 --channelID ch1 --name mycc --version 1.0 --sequence 1 --init-required --signature-policy "OR ('SampleOrg.member')" --peerAddresses 127.0.0.1:7051
```

## Next steps
```
CORE_PEER_ADDRESS=127.0.0.1:7051 peer chaincode invoke -o 127.0.0.1:7050 -C ch1 -n mycc -c '{"Args":["init","a","100","b","200"]}' --isInit
CORE_PEER_ADDRESS=127.0.0.1:7051 peer chaincode invoke -o 127.0.0.1:7050 -C ch1 -n mycc -c '{"Args":["invoke","a","b","10"]}'
CORE_PEER_ADDRESS=127.0.0.1:7051 peer chaincode invoke -o 127.0.0.1:7050 -C ch1 -n mycc -c '{"Args":["query","a"]}'
```
