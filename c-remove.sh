#!/bin/bash
raft_id=$1
echo '#######################################'
echo '#   Remove Tessera and Quorum   #'$raft_id'   #'
echo '#######################################'

geth --exec "raft.removePeer($raft_id)" attach qd/dd/geth.ipc

echo '################################'
echo '#            DONE!             #'
echo '################################'
