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
peer_info="enode://"$enode"@"$ip":"$[$node_index+30300]"?discport=0&raftport="$[$node_index+50400]""
echo $peer_info
n=1
while (( $n<=$node_index ))
do  
    qd=qdata_$n
    if [ -d "$qd" ]; then 
        break
    fi
    let n++
done

raft_id=`geth --exec "raft.addPeer('"$peer_info"')" attach qdata_$n/dd/geth.ipc`
echo "current node: #$node_index, consortium node: #$n, join: #$raft_id"
qd=qdata_$node_index
n=$node_index
PRIVATE_CONFIG=$qd/tm.ipc geth --datadir $qd/dd --networkid 99999 --raftjoinexisting $raft_id --permissioned --raft --rpc --rpcaddr 0.0.0.0 --rpcport "$[$n+22000]" --rpcapi admin,db,eth,debug,miner,net,shh,txpool,personal,web3,quorum,raft --port "$[$n+30300]" --nodiscover --unlock 0 --raftport "$[$n+50400]" --verbosity 4 --password $qd/passwords.txt --miner.gaslimit 18446744073709551615 --miner.gastarget 18446744073709551615 --raftblocktime 250 1>$qd/logs/geth.log 2>$qd/logs/geth.log &

echo "$raft_id" > $qd/RAFT_ID
echo '################################'
echo '#            DONE!             #'
echo '################################'
