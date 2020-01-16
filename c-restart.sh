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