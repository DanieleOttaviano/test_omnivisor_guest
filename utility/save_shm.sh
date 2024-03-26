#!/bin/bash

shm=0x46d00000

RESULTS_DIR="/root/tests/omnivisor/results"


mkdir -p ${RESULTS_DIR}/isolation_results
touch ${RESULTS_DIR}/isolation_results/${1}.txt
# Take result from shm and save in a txt file
> ${RESULTS_DIR}/isolation_results/${1}.txt

for i in {0..392..4}
do
	addr=$((${shm} + i))
	hex_value=$(devmem ${addr})
	printf "%d\n" ${hex_value} >> ${RESULTS_DIR}/isolation_results/${1}.txt
done

for i in {396..400..4}
do
        printf "%d\n" ${hex_value} >> ${RESULTS_DIR}/isolation_results/${1}.txt
done
