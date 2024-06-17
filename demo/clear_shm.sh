#!/bin/bash


shm=0x46d00000
DELTAS=(0x0 0x1000)

SIZE=4
COUNT=128

UPPER_LIMIT=$(($COUNT-1+2))
DEVMEM_SIZE=$(($SIZE * 8))

for DELTA in "${DELTAS[@]}"; do
    BASE=$(($shm+$DELTA))
    echo $BASE
    for i in $(eval echo {0..$UPPER_LIMIT})
    do
        addr=$((${BASE} + i * ${SIZE}))
        devmem ${addr} $DEVMEM_SIZE 0
    done
done
