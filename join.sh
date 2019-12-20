#!/bin/bash
node_index=$1
ip=$(hostname -i)
echo '#######################################'
echo '#   Join Tessera and Quorum   #'$node_index'   #'
echo '#######################################'

echo '[0] stop Quorum.'
# killall -9 geth
ps ax | grep "geth --datadir qdata_$node_index" | fgrep -v grep | awk '{ print $1 }' | xargs kill -9
ps aux | grep geth

echo '[0] stop Tessera'
killall -9 java
ps aux | grep tessera

sleep 10
rm -rf qdata_*/tm.ipc

### start Tessera ###
echo '[1] start Tessera.'
n=1
while (( $n<=$node_index ))
do  
    qd=qdata_$n
    if [ ! -d "$qd" ]; then 
        let n++
        continue
    fi  

    java -jar tessera.jar -configfile $qd/config.json >> $qd/logs/tessera.log 2>&1 &

    sleep 1
    let n++
done

# qd=qdata_$node_index
# java -jar tessera.jar -configfile $qd/config.json >> $qd/logs/tessera.log 2>&1 &


echo '[2] Wait Tessera starting.'
UDS_WAIT=10
n=1
while (( $n<=$node_index ))
do  
    qd=qdata_$n
    if [ ! -d "$qd" ]; then 
        let n++
        continue
    fi

    for i in $(seq 1 100)
      do
        strr=$(wget --timeout ${UDS_WAIT} -qO- --proxy off $(hostname -i):$[$n+9000]/upcheck)
        if [ "I'm up!" == "${strr}" ];
        then
            break
        else
            echo "Sleep ${UDS_WAIT} seconds. Waiting for TxManager-${n}."
            sleep ${UDS_WAIT}
        fi
    done
    let n++
done

### init genesis.json
echo '[3] init genesis.json.'
qd=qdata_$node_index
geth --datadir $qd/dd init $qd/genesis.json
sleep 1

### start quorum
echo '[4] start quorum.'
# enode=`bootnode -genkey "$qd"/dd/nodekey`
enode=`bootnode -nodekey "$qd"/dd/nodekey -writeaddress`
n=1
while (( $n<=$node_index ))
do  
    qd=qdata_$n
    if [ -d "$qd" ]; then 
        break
    fi
    let n++
done

join_number=`geth --exec "raft.addPeer('enode://"$enode"@"$ip":"$[$n+30300]"?discport=0&raftport="$[$n+50400]"')" attach qdata_$n/dd/geth.ipc`
echo "current node: #$node_index, consortium node: #$n, join: #$join_number"
qd=qdata_$node_index
n=$node_index
PRIVATE_CONFIG=$qd/tm.ipc geth --datadir $qd/dd --networkid 99999 --raftjoinexisting $join_number --permissioned --raft --rpc --rpcaddr 0.0.0.0 --rpcport "$[$n+22000]" --rpcapi admin,db,eth,debug,miner,net,shh,txpool,personal,web3,quorum,raft --port "$[$n+30300]" --nodiscover --unlock 0 --raftport "$[$n+50400]" --verbosity 4 --password $qd/passwords.txt --miner.gaslimit 18446744073709551615 --miner.gastarget 18446744073709551615 --raftblocktime 250 1>$qd/logs/geth.log 2>$qd/logs/geth.log &


echo '################################'
echo '#            DONE!             #'
echo '################################'


# n=$1  # current node
# xnode=$2 # one node in consortium
# ip=$(hostname -i)
# echo '################################'
# echo '#             Join             #'
# echo '################################'
# enode=`bootnode -nodekey "q$n/nodekey" -writeaddress`
# join_number=`geth --exec "raft.addPeer('enode://"$enode"@"$ip":"$[$n+21000]"?discport=0&raftport="$[$n+30300]"')" attach q$xnode/geth.ipc`
# echo "current node: #$n, consortium node: #$xnode, join: #$join_number"
# PRIVATE_CONFIG=ignore nohup geth --datadir q$n --nodiscover --verbosity 5 --networkid 99999 --raft --raftport $[$n+30300] --raftjoinexisting $join_number --rpc --rpcaddr 0.0.0.0 --rpcport $[$n+22000] --rpcapi admin,db,eth,debug,miner,net,shh,txpool,personal,web3,quorum,raft --emitcheckpoints --port $[$n+21000] >> q$n/geth.log 2>&1 &
