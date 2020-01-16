#!/bin/bash
echo '################################'
echo '#   Start Tessera and Quorum   #'
echo '################################'

echo '[1] Start Tessera.'
n=1
qd=qd

java -jar tessera.jar -configfile $qd/config.json >> $qd/logs/tessera.log 2>&1 &

echo '[2] Wait Tessera starting.'
UDS_WAIT=10
 
for i in $(seq 1 30)
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

echo '[3] Init genesis.json.'
geth --datadir $qd/dd init $qd/genesis.json
sleep 1

echo '[4] Start quorum.'
PRIVATE_CONFIG=$qd/tm.ipc geth --datadir $qd/dd --networkid 99999 --permissioned --raft --rpc --rpcaddr 0.0.0.0 --rpcport "$[$n+22000]" --rpcapi admin,db,eth,debug,miner,net,shh,txpool,personal,web3,quorum,raft --port "$[$n+30300]" --nodiscover --unlock 0 --raftport "$[$n+50400]" --verbosity 4 --password $qd/passwords.txt --miner.gaslimit 18446744073709551615 --miner.gastarget 18446744073709551615 --raftblocktime 250 1>$qd/logs/geth.log 2>$qd/logs/geth.log &
sleep 1



echo '################################'
echo '#            DONE!             #'
echo '################################'
