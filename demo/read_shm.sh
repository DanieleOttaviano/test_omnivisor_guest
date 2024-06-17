#!/bin/bash

usage() {
	echo -e "\
Usage: $0 [-c] [-h]
This script reads the shared memory queue of a remote core:
    [-c <CORE> Read shm queue of <CORE> remote core (RISCV|RPU)]
    [-h help]" 1>&2
    exit 1
}

while getopts "c:h" o; do
    case "${o}" in
        c)
            core=${OPTARG}
            ;;
        h)
            usage
            ;;
        *)
            usage
            ;;
    esac
done

# Check Inputs
if [[ $core != "RPU" && $core != "RISCV" ]]; then
	echo "Error: Invalid remote core specified: ${core}"
    echo "Valid cores: RPU, RISCV"
	usage
	exit 1
fi

shm=0x46d00000
RISCV_DELTA=0x1000

if [[ $core == "RISCV" ]]; then
    shm=$(($shm + $RISCV_DELTA))
fi

SIZE=4
COUNT=128

UPPER_LIMIT=$(($COUNT-1))
# MOD_VAL=$(($COUNT * $SIZE))

WRITE_PTR_ADDR=$((${shm} + ($COUNT) * ${SIZE}))
READ_PTR_ADDR=$((${shm} + ($COUNT + 1) * ${SIZE}))

write_ptr=$(devmem ${WRITE_PTR_ADDR})
$(devmem ${READ_PTR_ADDR} 32 ${write_ptr})

while : ; do
    write_ptr=$(devmem ${WRITE_PTR_ADDR})
    read_ptr=$(devmem ${READ_PTR_ADDR})

    if [[ $read_ptr == $write_ptr ]]; then
        usleep 50000
    else
        read_addr=$(($read_ptr * 4 + $shm))

        val=$(devmem ${read_addr})

        read_ptr=$((($read_ptr + 1) % $COUNT))
        
        $(devmem ${READ_PTR_ADDR} 32 ${read_ptr})
        echo $(($val))
    fi
done