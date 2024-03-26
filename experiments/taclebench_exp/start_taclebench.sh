#!/bin/bash

source /etc/profile
echo $$ >> /sys/fs/cgroup/cpuset/test/cgroup.procs

usage() {
	echo -e "Usage: $0 \r\n \
  		This script launch the taclebench test on the selected processor:\r\n \
    		[-c <core under test> (RPU, RISCV)]\r\n \
    		[-n <Test Name Extension>]\r\n \
            [-r <Repetitions>]\r\n \
    		[-h help]" 1>&2
	 exit 1
}

#DIRECTORIES
JAIL_SCRIPT_PATH="/root/scripts_jailhouse_kria"
TACLE_EXP_PATH="/root/tests/omnivisor/experiments/taclebench_exp"
BENCH_DIR="/root/tests/omnivisor/experiments/taclebench_exp/inmates"
RES_DIR="/root/tests/omnivisor/results/taclebench_results/"
CELL_PATH="/root/jailhouse/configs/arm64"
UTILITY_PATH="/root/tests/omnivisor/utility"
OUTPUT_LOG="/dev/null" #"/tmp/boot_time.log"

KEEP=0

#shm
shm=0x46d00000

while getopts "c:n:r:hok" o; do
    case "${o}" in
        k)
            KEEP=1
            ;;
        c)
			core=${OPTARG}
            ;;
        n)
            NAME_EXTENSION=${OPTARG}
            ;;
        r)
            REPETITIONS=${OPTARG}
            ;;
        h)
            usage
            ;;
        *)
            usage
            ;;
    esac
done

echo "Test name: <benchname>${NAME_EXTENSION}"
echo "Repetitions: ${REPETITIONS}"

# Check Inputs
if [[ $core != "RPU" && $core != "RISCV" ]]; then
	echo "Error: Invalid core under test specified: ${core}"
    echo "Valid cores: RPU, RISCV"
	usage
	exit 1
fi
if [[ $REPETITIONS -lt 1 ]]; then
    echo "Error: Invalid number of repetitions specified: ${REPETITIONS}"
    usage
    exit 1
fi

# Remove kernel prints
echo "1" > /proc/sys/kernel/printk

# Clean Shared Memory
devmem ${shm} 32 0x00000000

# Get the list of directory names under bench/
directories=$(ls -d ${BENCH_DIR}/*/ | xargs -n1 basename)

for bench_name in $directories; do
    echo Running: ${bench_name}
    # Create the directory for the results and clean it if already exist
    mkdir -p ${RES_DIR}/${bench_name}
    if [[ $KEEP -eq 0 ]]; then
        touch ${RES_DIR}/${bench_name}/${bench_name}${NAME_EXTENSION}.txt
        > ${RES_DIR}/${bench_name}/${bench_name}${NAME_EXTENSION}.txt
        rep=0
    else
        rep=$(wc -l ${RES_DIR}/${bench_name}/${bench_name}${NAME_EXTENSION}.txt | awk '{print $1}')
    fi


    echo "${bench_name} KEEP=${KEEP} ${rep}"
    # break

    # Check if the benchmark is in the ignore list
    if grep -q "${bench_name}" ${TACLE_EXP_PATH}/${core}_ignore.txt; then
        touch ${RES_DIR}/${bench_name}/${bench_name}${NAME_EXTENSION}.txt
        > ${RES_DIR}/${bench_name}/${bench_name}${NAME_EXTENSION}.txt
        time=0
        for ((rep=0; rep<${REPETITIONS}; rep++)); do
            printf "%d\n" ${time} >> ${RES_DIR}/${bench_name}/${bench_name}${NAME_EXTENSION}.txt
            printf "TIME: %d\n (skipped)\n" ${time}  
        done
        continue
    fi

    for ((; rep<${REPETITIONS}; rep++)); do
        # echo "INSIDE!!"
        # continue

        # Start Test
        jailhouse cell create ${BENCH_DIR}/${bench_name}/${core}-${bench_name}.cell >> ${OUTPUT_LOG} 2>&1
        if [[ "${core}" == "RPU" ]]; then
            jailhouse cell load inmate-demo-${core} ${BENCH_DIR}/${bench_name}/${core}-${bench_name}-demo_tcm.bin -a 0xffe00000 ${BENCH_DIR}/${bench_name}/${core}-${bench_name}-demo.bin >> ${OUTPUT_LOG} 2>&1 
        elif [[ "${core}" == "RISCV" ]]; then
            jailhouse cell load inmate-demo-${core} ${BENCH_DIR}/${bench_name}/${core}-${bench_name}-demo.bin >> ${OUTPUT_LOG} 2>&1
        fi
        jailhouse cell start inmate-demo-${core} >> ${OUTPUT_LOG} 2>&1

        # Wait for the RPU to produce the results
        usleep 100000
        while [ "$(devmem ${shm})" == "0x00000000" ];do
            usleep 100000
        done 
        
        # Write results to the file
        time=$(devmem ${shm})
        printf "%d\n" ${time} >> ${RES_DIR}/${bench_name}/${bench_name}${NAME_EXTENSION}.txt
        printf "TIME: %d\n" ${time} 

        # Clean Shared Memory
        devmem ${shm} 32 0x00000000
        # Destroy RPU Cell
        jailhouse cell destroy inmate-demo-${core}
        wait
        usleep 100000
    done
done
