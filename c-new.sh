#!/bin/bash
ip=${1:-$(hostname -i)}
echo '################################'
echo '#   Configuring for new node   #'
echo '################################'

n=1
qd=qd

echo '[1] Stop Quorum and Tessera, and clean them.'
killall -9 geth
killall -9 java
sleep 3
rm -rf $qd

mkdir -p $qd/{logs,keys}
mkdir -p $qd/dd/geth

### create static-nodes.json and nodekeys ###

echo '[2] Creating nodekeys and static-nodes.json.'

# Generate the node key
enode=`bootnode -genkey "$qd"/dd/nodekey`

echo "[" > static-nodes.json
# Generate the node's Enode
enode=`bootnode -nodekey "$qd"/dd/nodekey -writeaddress`
# Add the enode to static-nodes.json
echo '  "enode://'$enode'@'$ip':'$[$n+30300]'?discport=0&raftport='$[$n+50400]'"'$sep >> static-nodes.json
echo "]" >> static-nodes.json

### copy static-nodes.json in to qdata_n/dd folder ###

echo '[3] copy static-nodes.json into qdata folder'

cp static-nodes.json $qd/dd/static-nodes.json
cp static-nodes.json $qd/dd/permissioned-nodes.json 

rm -rf static-nodes.json

#### Create accounts, keys and genesis.json file ####

echo '[4] Creating Ether accounts and genesis.json.'
touch $qd/passwords.txt
account=`geth --datadir="$qd"/dd --password "$qd"/passwords.txt account new | cut -c 11-50`

### 
#   "alloc": {
#     "0x${account}": {
#       "balance": "1000000000000000000000000000"
#     }
#   },

cat > $qd/genesis.json <<EOF
{
  "alloc": {
  },
  "coinbase": "0x0000000000000000000000000000000000000000",
  "config": {
    "homesteadBlock": 0,
    "byzantiumBlock": 0,
    "constantinopleBlock":0,
    "chainId": 10,
    "eip150Block": 0,
    "eip155Block": 0,
    "eip150Hash": "0x0000000000000000000000000000000000000000000000000000000000000000",
    "eip158Block": 0,
    "isQuorum":true
  },
  "difficulty": "0x0",
  "extraData": "0x",
  "gasLimit": "0xFFFFFFFFFFFFFFFF",
  "mixhash": "0x00000000000000000000000000000000000000647572616c65787365646c6578",
  "nonce": "0x0",
  "parentHash": "0x0000000000000000000000000000000000000000000000000000000000000000",
  "timestamp": "0x00"
}
EOF

#### Creating Tessera keys ####

echo '[5] Create the Tessera keys.'

java -jar tessera.jar -keygen -filename tm < /dev/null > /dev/null
echo "public key: $(cat tm.pub)"
mv tm.key $qd/keys/
mv tm.pub $qd/keys/



echo '[6] Create the Tessera config.'

#### Make node list for config.json ########################################

nodelist='{"url":"http://'${ip}':'$[$n+9000]'"}'

cat > ${qd}/config.json <<EOF
{
"useWhiteList": false,
"jdbc": {
    "username": "sa",
    "password": "",
    "url": "jdbc:h2:$(pwd)/${qd}/db1;MODE=Oracle;TRACE_LEVEL_SYSTEM_OUT=0",
    "autoCreateTables": true
},
"serverConfigs":[
    {
        "app":"ThirdParty",
        "enabled": true,
        "serverAddress": "http://${ip}:$[$n+9080]",
        "communicationType" : "REST"
    },
    {
        "app":"Q2T",
        "enabled": true,
        "serverAddress":"unix:$(pwd)/${qd}/tm.ipc",
        "communicationType" : "REST"
    },
    {
        "app":"P2P",
        "enabled": true,
        "serverAddress":"http://${ip}:$[$n+9000]",
        "sslConfig": {
            "tls": "OFF"
        },
        "communicationType" : "REST"
    }
],
"peer": [
    ${nodelist}
],
"keys": {
    "passwords": [],
    "keyData": [
        {
            "privateKeyPath": "$(pwd)/${qd}/keys/tm.key",
            "publicKeyPath": "$(pwd)/${qd}/keys/tm.pub"
        }
    ]
},
"alwaysSendTo": []
}
EOF


echo '################################'
echo '#             DONE!            #'
echo '################################'
