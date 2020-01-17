#!/bin/bash
echo '################################'
echo '#   Configuring for cleaning   #'
echo '################################'

qd=qd

echo '[1] Stop Quorum and Tessera, and clean them.'
killall -9 geth
killall -9 java
rm -rf $qd

echo '################################'
echo '#             DONE!            #'
echo '################################'
