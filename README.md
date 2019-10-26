# quorum-tessera-raft
Quorum with Tessera using Raft consensus algorithm for multiple node setup without docker.



 



# ENV requirement

## Test system version

Go 1.12.5

JAVA 8

Quorum 2.3.0

Tessera 0.10.0





# How to use

## Create files

```
bash setup.sh <node numbers>
```

This shell script will create all files for Quorum and Tessera needed including Tessera 0.10.0.

`node number` is quorum numbers you want to setup.

## Start Quorum and Tessera

```
bash start.sh <node numbers>
```

This shell script will start Tessera and Quorum.



## clean

```
bash clean.sh <node numbers>
```

This shell script will stop all Java processes and geth processes.



## Easy test

```
bash re-setup.sh <node numbers>
```

This shell script will execuate `clean.sh`, `setup.sh` and `start.sh`.

