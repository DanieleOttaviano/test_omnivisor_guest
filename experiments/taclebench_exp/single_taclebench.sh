#!/bin/bash

source /etc/profile
echo $$ >> /sys/fs/cgroup/cpuset/test/cgroup.procs

usage() {
	echo -e "Usage: $0 \r\n \
  		This script launch the taclebench test on the selected processor:\r\n \
    		[-c <core under test> (RPU, RISCV)]\r\n \
    		[-b <Benchmark name>]\r\n \
    		[-h help]" 1>&2
	 exit 1
}

# DIRECTORIES
source "$(dirname "$0")/../../utility/default_directories.sh"
OUTPUT_LOG="/dev/null" #"/tmp/boot_time.log"

#shm
shm=0x46d00000
shm_freq=0x46d00008

# Clean Shared Memory
devmem ${shm} 32 0x00000000

while getopts "c:b:h" o; do
    case "${o}" in
        c)
			core=${OPTARG}
            ;;
        b)
            bench_name=${OPTARG}
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
	echo "Error: Invalid core under test specified: ${core}"
    echo "Valid cores: RPU, RISCV"
	usage
    exit 1
fi
if [[ -z $bench_name ]]; then
    echo "Error: No bench name provided"
	usage
    exit 1
fi
if [[ ! -f "${BENCH_DIR}/${bench_name}/${core}-${bench_name}.cell" ]]; then
    echo "Benchmark file not found"
	usage
    exit 1
fi

# Start Test
jailhouse cell create ${BENCH_DIR}/${bench_name}/${core}-${bench_name}.cell >> ${OUTPUT_LOG}
if [[ "${core}" == "RPU" ]]; then
    jailhouse cell load inmate-demo-${core} ${BENCH_DIR}/${bench_name}/${core}-${bench_name}-demo_tcm.bin -a 0xffe00000 ${BENCH_DIR}/${bench_name}/${core}-${bench_name}-demo.bin >> ${OUTPUT_LOG}
elif [[ "${core}" == "RISCV" ]]; then
    jailhouse cell load inmate-demo-${core} ${BENCH_DIR}/${bench_name}/${core}-${bench_name}-demo.bin >> ${OUTPUT_LOG}
fi
jailhouse cell start inmate-demo-${core} >> ${OUTPUT_LOG}

# Wait for the RPU to produce the results
usleep 100000
while [ "$(devmem ${shm})" == "0x00000000" ]; do
    usleep 100000
done 


if [[ "$core" == "RISCV"  ]]; then
    # Write results to the file
    time=$(devmem ${shm} 64)
    time=`printf %d "${time}"`

    freq=$(devmem ${shm_freq} 64)
    freq=`printf %d "${freq}"`

    time=`echo "${time} / ${freq}" | bc`

    # Clean Shared Memory
    devmem ${shm} 64 0x00000000
else
    # Write results to the file
    time=$(devmem ${shm})

    # Clean Shared Memory
    devmem ${shm} 32 0x00000000
fi

printf "%d\n" ${time}

# Destroy RPU Cell
jailhouse cell destroy inmate-demo-${core}
wait
# usleep 100000