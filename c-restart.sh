#!/bin/bash
ip=$(hostname -i)
echo '#################################'
echo '#   Restart Tessera and Quorum  #'
echo '#################################'

n=1
qd=qd

echo '[1] Stop Quorum and Tessera.'
killall -9 geth
killall -9 java

sleep 10
rm -rf $qd/tm.ipc


echo '[2] Restart Tessera.'
java -jar tessera.jar -configfile $qd/config.json >> $qd/logs/tessera.log 2>&1 &
sleep 1

geth --datadir $qd/dd init $qd/genesis.json
sleep 1
PRIVATE_CONFIG=$qd/tm.ipc geth --datadir $qd/dd --networkid 99999 --permissioned --raft --rpc --rpcaddr 0.0.0.0 --rpcport "$[$n+22000]" --rpcapi admin,db,eth,debug,miner,net,shh,txpool,personal,web3,quorum,raft --port "$[$n+30300]" --nodiscover --unlock 0 --raftport "$[$n+50400]" --verbosity 4 --password $qd/passwords.txt --miner.gaslimit 18446744073709551615 --miner.gastarget 18446744073709551615 --raftblocktime 250 1>$qd/logs/geth.log 2>$qd/logs/geth.log &
