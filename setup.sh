#!/bin/bash
node_number=$1
ip=$(hostname -i)
echo '################################'
echo '#   Configuring for '$node_number' nodes.   #'
echo '################################'
### Create directories for each node's configuration ###
echo '################################'
echo '[1] create the folders'


n=1
while (( $n<=$node_number ))
do
    qd=qdata_$n
    mkdir -p $qd/{logs,keys}
    mkdir -p $qd/dd/geth
    let n++
done

### Make static-nodes.json and store keys ###

echo '[2] Creating Enodes and static-nodes.json.'

echo "[" > static-nodes.json
n=1
while (( $n<=$node_number ))
do
    qd=qdata_$n

    # Generate the node's Enode and key
    enode=`bootnode -genkey "$qd"/dd/nodekey`
    enode=`bootnode -nodekey "$qd"/dd/nodekey -writeaddress`

    # Add the enode to static-nodes.json
    echo ' '$enode'@'$ip' '
    sep=`[[ $n !=  $node_number ]] && echo ","`
    echo '  "enode://'$enode'@'$ip':3030'$n'?discport=0&raftport=5040'$n'"'$sep >> static-nodes.json
    let n++
done
echo "]" >> static-nodes.json

### copy static-nodes.json in to qdata_n/dd folder #############################

echo '[3] copy static-nodes.json into qdata folder'
n=1
while (( $n<=$node_number ))
do
    qd=qdata_$n
    
    cp static-nodes.json $qd/dd/static-nodes.json
    cp static-nodes.json $qd/dd/permissioned-nodes.json 

    let n++
done
rm -rf static-nodes.json

#### Create accounts, keys and genesis.json file #######################

echo '[4] Creating Ether accounts and genesis.json.'

cat > genesis.json <<EOF
{
  "alloc": {
EOF

n=1
while (( $n<=$node_number ))
do
    qd=qdata_$n

    # Generate an Ether account for the node
    touch $qd/passwords.txt
    account=`geth --datadir="$qd"/dd --password "$qd"/passwords.txt account new | cut -c 11-50`

    # Add the account to the genesis block so it has some Ether at start-up
    sep=`[[ $n != $node_number ]] && echo ","`
    cat >> genesis.json <<EOF
    "0x${account}": {
      "balance": "1000000000000000000000000000"
    }${sep}
EOF

    let n++
done

cat >> genesis.json <<EOF
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

#### Copy genesis.json into qdata_n folder #######################

echo '[5] Creating Ether accounts and genesis.json.'

n=1
while (( $n<=$node_number ))
do
    qd=qdata_$n
    cp genesis.json $qd/genesis.json
    let n++
done

rm -rf genesis.json 


#### Complete each node's configuration ####

echo '[6] Download the Tessera.'

wget -q https://oss.sonatype.org/service/local/repositories/releases/content/com/jpmorgan/quorum/tessera-app/0.10.0/tessera-app-0.10.0-app.jar 

mv tessera-app-0.10.0-app.jar tessera.jar


#### Creating Tessera keys ####

echo '[7] create the Tessera keys.'

n=1
while (( $n<=$node_number ))
do  
    qd=qdata_$n

    java -jar tessera.jar -keygen -filename tm < /dev/null > /dev/null
    echo "node-${n} public key: $(cat tm.pub)"
    mv tm.key $qd/keys/
    mv tm.pub $qd/keys/

    let n++
done


#### Complete each node's configuration ####

echo '[8] Create the Tessera config.'

#### Make node list for config.json ########################################
nodelist=''
n=1
while (( $n<=$node_number ))
do
    sep=`[[ $n != 1 ]] && echo ","`
    nodelist=${nodelist}${sep}'{"url":"http://'${ip}':900'$n'"}'
    let n++
done


n=1
while (( $n<=$node_number ))
do
    qd=qdata_$n
cat >> ${qd}/config.json <<EOF
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
        "serverAddress": "http://${ip}:908${n}",
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
        "serverAddress":"http://${ip}:900${n}",
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

let n++
done


echo '################################'
echo '#             DONE!            #'
echo '################################'
