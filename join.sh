#!/bin/bash
n=$1  # current node
xnode=$2 # one node in consortium
ip=$(hostname -i)
echo '################################'
echo '#             Join             #'
echo '################################'
enode=`bootnode -nodekey "q$n/nodekey" -writeaddress`
join_number=`geth --exec "raft.addPeer('enode://"$enode"@"$ip":"$[$n+21000]"?discport=0&raftport="$[$n+30300]"')" attach q$xnode/geth.ipc`
echo "current node: #$n, consortium node: #$xnode, join: #$join_number"
PRIVATE_CONFIG=ignore nohup geth --datadir q$n --nodiscover --verbosity 5 --networkid 99999 --raft --raftport $[$n+30300] --raftjoinexisting $join_number --rpc --rpcaddr 0.0.0.0 --rpcport $[$n+22000] --rpcapi admin,db,eth,debug,miner,net,shh,txpool,personal,web3,quorum,raft --emitcheckpoints --port $[$n+21000] >> q$n/geth.log 2>&1 &
echo '################################'
echo '#             DONE!            #'
echo '################################'