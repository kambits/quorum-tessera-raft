#!/bin/bash
node_index=$1
ip=$(hostname -i)
echo '#######################################'
echo '#   Remove Tessera and Quorum   #'$node_index'   #'
echo '#######################################'

echo '[0] stop Quorum.'
# killall -9 geth
ps ax | grep "geth --datadir qdata_$node_index" | fgrep -v grep | awk '{ print $1 }' | xargs kill -9
ps aux | grep geth

echo '[0] stop Tessera'
# killall -9 java
ps ax | grep "tessera.jar -configfile qdata_$node_index" | fgrep -v grep | awk '{ print $1 }' | xargs kill -9
ps aux | grep tessera

sleep 1

qd=qdata_$node_index
raft_id=$node_index
if [ -f "$qd/RAFT_ID" ]; then
    raft_id=$(< $qd/RAFT_ID)
fi

n=1
found=0
while (( $n<$node_index ))
do  
    qd=qdata_$n
    if [ -d "$qd" ]; then 
        echo "1.Found #$n"
        found=1
        break
    fi
    let n++
done

if [ ! $found ]; then 
    n=$[$node_index+1]
    while (( $n<$[$node_index+50] ))
    do  
        qd=qdata_$n
        if [ -d "$qd" ]; then 
            echo "2.Found #$n"
            found=1
            break
        fi
        let n++
    done
fi

if [ ! $found ]; then 
    echo "No avaliable node to attach!"
    exit 1
fi

echo "remove node: #$node_index, raft id: #$raft_id, attach node: #$n"
geth --exec "raft.removePeer($raft_id)" attach qdata_$n/dd/geth.ipc

rm -rf qdata_$node_index

echo '################################'
echo '#            DONE!             #'
echo '################################'
