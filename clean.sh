#!/bin/bash
num=5

echo '################################'
echo '#             Clean            #'
echo '################################'


echo '[1] stop Quorum.'
killall -9 geth

echo '[2] stop Tessera'
killall -9 java

echo '[3] delete files.'
n=1
while (( $n<=$num ))
do
    qd=qdata_$n
    rm -rf $qd
    let n++
done

echo '################################'
echo '#             DONE!            #'
echo '################################'
