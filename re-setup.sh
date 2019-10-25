#!/bin/bash

bash clean.sh $1
bash setup.sh $1
bash start.sh $1
ps -aux | grep geth 
ps -aux | grep tessera