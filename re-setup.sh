#!/bin/bash

bash clean.sh
bash setup.sh
bash start.sh
ps -aux | grep geth 
ps -aux | grep tessera