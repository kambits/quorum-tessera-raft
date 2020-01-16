#!/bin/bash
master_ip=$1
ip=$(hostname -i)
echo '##############################'
echo '#   Join Tessera and Quorum  #'
echo '##############################'

n=1
qd=qd

### MODIFY all node' configs: config.json, static-nodes.json, permissioned-nodes.json 
### c-restart.sh
### All upcheck: curl http://35.171.82.73:9001/upcheck


### init genesis.json
echo '[3] Init genesis.json.'
geth --datadir $qd/dd init $qd/genesis.json
sleep 1

echo '[4] Start Quorum.'
enode=`bootnode -nodekey "$qd"/dd/nodekey -writeaddress`
peer_info="enode://"$enode"@"$ip":"$[$n+30300]"?discport=0&raftport="$[$n+50400]""
echo $peer_info

raft_id=`geth --exec "raft.addPeer('"$peer_info"')" attach http://$master_ip:22001`
echo "current node: #$ip, consortium node: #$master_ip, join: #$raft_id"

PRIVATE_CONFIG=$qd/tm.ipc geth --datadir $qd/dd --networkid 99999 --raftjoinexisting $raft_id --permissioned --raft --rpc --rpcaddr 0.0.0.0 --rpcport "$[$n+22000]" --rpcapi admin,db,eth,debug,miner,net,shh,txpool,personal,web3,quorum,raft --port "$[$n+30300]" --nodiscover --unlock 0 --raftport "$[$n+50400]" --verbosity 4 --password $qd/passwords.txt --miner.gaslimit 18446744073709551615 --miner.gastarget 18446744073709551615 --raftblocktime 250 1>$qd/logs/geth.log 2>$qd/logs/geth.log &

echo "$raft_id" > $qd/RAFT_ID
echo '################################'
echo '#            DONE!             #'
echo '################################'
