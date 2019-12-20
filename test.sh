#!/bin/bash

bash clean.sh 4
bash re-setup.sh 3
bash setup_new_node.sh 4
bash join.sh 4
ps -aux | grep geth 
ps -aux | grep tessera