#!/bin/bash
node_number=$1

echo '################################'
echo '#             Clean            #'
echo '################################'


echo '[1] stop Quorum.'
killall -9 geth

echo '[2] stop Tessera'
killall -9 java

echo '[3] delete files.'
n=1
while (( $n<=$node_number ))
do
    qd=qdata_$n
    rm -rf $qd
    let n++
done
rm -rf tessera.jar

echo '################################'
echo '#             DONE!            #'
echo '################################'
