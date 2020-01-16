#!/bin/bash
node_index=$1 
ip=$(hostname -i)
echo '################################'
echo '#   Configuring for node #'$node_index'   #'
echo '################################'

### Create directories for each node's configuration ###
echo '[1] create the folders'

qd=qdata_$node_index
mkdir -p $qd/{logs,keys}
mkdir -p $qd/dd/geth

### create static-nodes.json and nodekeys ###

echo '[2] Creating nodekeys and static-nodes.json.'

# Generate the node key
enode=`bootnode -genkey "$qd"/dd/nodekey`

echo "[" > static-nodes.json
n=1
while (( $n<=$node_index ))
do
    qd=qdata_$n
    if [ -d "$qd" ]; then
        # Generate the node's Enode
        enode=`bootnode -nodekey "$qd"/dd/nodekey -writeaddress`

        # Add the enode to static-nodes.json
        echo ' '$enode'@'$ip' '
        sep=`[[ $n !=  $node_index ]] && echo ","`
        echo '  "enode://'$enode'@'$ip':'$[$n+30300]'?discport=0&raftport='$[$n+50400]'"'$sep >> static-nodes.json
        
    fi
    let n++
done
echo "]" >> static-nodes.json

### copy static-nodes.json in to qdata_n/dd folder ###

echo '[3] copy static-nodes.json into qdata folder'
n=1
while (( $n<=$node_index ))
do
    qd=qdata_$n
    if [ -d "$qd" ]; then    
        cp static-nodes.json $qd/dd/static-nodes.json
        cp static-nodes.json $qd/dd/permissioned-nodes.json 
    fi
    let n++
done
rm -rf static-nodes.json

#### Create accounts, keys and genesis.json file ####

echo '[4] Creating Ether accounts and genesis.json.'

cat > genesis.json <<EOF
{
  "alloc": {
EOF

qd=qdata_$node_index
# Generate an Ether account for the node
touch $qd/passwords.txt
account=`geth --datadir="$qd"/dd --password "$qd"/passwords.txt account new | cut -c 11-50`

#### Copy genesis.json into qdata_n folder #######################

echo '[5] copy genesis.json into qdata folder.'

n=1
while (( $n<$node_index ))
do
    qd=qdata_$n
    if [ -d "$qd" ]; then 
        cp $qd/genesis.json qdata_$node_index/genesis.json
        break
    fi
    let n++
done

#### Creating Tessera keys ####

echo '[6] create the Tessera keys.'


qd=qdata_$node_index
java -jar tessera.jar -keygen -filename tm < /dev/null > /dev/null
echo "node-${node_index} public key: $(cat tm.pub)"
mv tm.key $qd/keys/
mv tm.pub $qd/keys/



#### Complete each node's configuration ####

echo '[8] Create the Tessera config.'

#### Make node list for config.json ########################################
nodelist=''
n=1
while (( $n<=$node_index ))
do
    qd=qdata_$n
    if [ -d "$qd" ]; then 
        sep=`[[ $n !=  $node_index ]] && echo ","`
        nodelist=${nodelist}'{"url":"http://'${ip}':'$[$n+9000]'"}'${sep}
    fi
    let n++
done


n=1
while (( $n<=$node_index ))
do
    qd=qdata_$n
    if [ ! -d "$qd" ]; then 
        let n++
        continue
    fi
    echo 'writing '${qd}'/config.json'

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

let n++
done


echo '################################'
echo '#             DONE!            #'
echo '################################'
