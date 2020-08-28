#!/bin/bash

bash clean.sh $1
bash setup.v2.7.sh $1
bash start.v2.7.sh $1
ps -aux | grep geth 
ps -aux | grep tessera