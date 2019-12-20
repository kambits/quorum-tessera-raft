#!/bin/bash
node_number=$1
node_index=${2:-1}    
ip=$(hostname -i)
echo '################################'
echo '#   Configuring for '$node_number' nodes.  node index: '$node_index' #'
echo '################################'