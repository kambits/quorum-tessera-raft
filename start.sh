#!/bin/bash
node_number=5
echo '################################'
echo '#   Start Tessera and Quorum   #'
echo '################################'

### start Tessera ###
echo '[1] start Tessera.'
n=1
while (( $n<=$node_number ))
do
    qd=qdata_$n

    java -jar tessera.jar -configfile $qd/config.json >> $qd/logs/tessera.log 2>&1 &

    let n++
done

echo '[2] Wait Tessera starting.'
UDS_WAIT=10
n=1
while (( $n<=$node_number ))
do  
    for i in $(seq 1 100)
      do
        strr=$(wget --timeout ${UDS_WAIT} -qO- --proxy off $(hostname -i):900${n}/upcheck)
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
n=1
while (( $n<=$node_number ))
do
    qd=qdata_$n
    
    geth --datadir $qd/dd init $qd/genesis.json

    let n++
done
sleep 1

### start quorum
echo '[4] start quorum.'
n=1
while (( $n<=$node_number ))
do
    qd=qdata_$n
    
    PRIVATE_CONFIG=$qd/tm.ipc geth --datadir $qd/dd --permissioned --raft --rpc --rpcaddr 0.0.0.0 --rpcport "2200$n" --rpcapi admin,db,eth,debug,miner,net,shh,txpool,personal,web3,quorum,raft --port "3030$n" --nodiscover --unlock 0 --raftport "5040$n" --verbosity 4 --password $qd/passwords.txt --miner.gaslimit 18446744073709551615 --miner.gastarget 18446744073709551615 --raftblocktime 250 1>$qd/logs/geth.log 2>$qd/logs/geth.log &
    sleep 1
    let n++
done


echo '################################'
echo '#            DONE!             #'
echo '################################'
