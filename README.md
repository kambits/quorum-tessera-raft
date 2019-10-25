# quorum-tessera-raft
Quorum with Tessera using Raft consensus algorithm for multiple node setup.





# ENV requirement

## Test system version

Go 1.12.5

JAVA 8

Quorum 2.3.0

Tessera 0.10.0





# How to use

## Edit node number

Change the `node_number` at the `setup.sh` ,`start.sh` and `clean.sh`on the line 2. The default `node_number` is 5.



## Create files

```
bash setup.sh
```

This shell script will create all files the Quorum and Tessera need including Tessera 0.10.0.

## Start Quorum and Tessera

```
bash start.sh
```

This shell script will start Tessera and Quorum.



## clean

```
bash clean.sh
```

This shell script will stop all Java processes and geth processes.



## Easy test

```
bash re-setup.sh
```

This shell script will execuate `clean.sh`, `setup.sh` and `start.sh`.

