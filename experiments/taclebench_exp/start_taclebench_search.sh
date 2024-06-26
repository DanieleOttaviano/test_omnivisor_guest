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

# DIRECTORIES
source "$(dirname "$0")/../../utility/default_directories.sh"

#shm
shm=0x46d00000

RPU_BANDWIDTH=10
FPGA_BANDWIDTH=10
APU_BANDWIDTH=78

TMP_RPU_BANDWIDTH=10
TMP_FPGA_BANDWIDTH=14
TMP_APU_BANDWIDTH=950

LAST_RPU_BANDWIDTH=0
LAST_FPGA_BANDWIDTH=0
LAST_APU_BANDWIDTH=0

TARGET_SLOWDOWN=1.5
MAX_REPETITIONS=10

while getopts "R:F:A:t:c:n:r:h" o; do
    case "${o}" in
        R)
            TMP_RPU_BANDWIDTH=${OPTARG}
            ;;
        F)
            TMP_FPGA_BANDWIDTH=${OPTARG}
            ;;
        A)
            TMP_APU_BANDWIDTH=${OPTARG}
            ;;
        t)
            TARGET_SLOWDOWN=${OPTARG}
            ;;
        c)
			core=${OPTARG}
            ;;
        n)
            NAME_EXTENSION=${OPTARG}_search
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
    mkdir -p ${TACLEBENCH_RES_DIR}/${bench_name}
    touch ${TACLEBENCH_RES_DIR}/${bench_name}/${bench_name}${NAME_EXTENSION}.txt
    > ${TACLEBENCH_RES_DIR}/${bench_name}/${bench_name}${NAME_EXTENSION}.txt

    # Check if the benchmark is in the ignore list
    if grep -q "${bench_name}" ${TACLE_EXP_PATH}/${core}_ignore.txt; then
        time=0
        for ((rep=0; rep<${REPETITIONS}; rep++)); do
            printf "%d\n" ${time} >> ${TACLEBENCH_RES_DIR}/${bench_name}/${bench_name}${NAME_EXTENSION}.txt
            printf "TIME: %d\n (skipped)\n" ${time}  
        done
        continue
    fi

    # Write some headers
    echo "# ${REPETITIONS} repetitions for ${bench_name}" >> ${TACLEBENCH_RES_DIR}/${bench_name}/${bench_name}${NAME_EXTENSION}.txt
    echo "# Target slowdown: ${TARGET_SLOWDOWN}" >> ${TACLEBENCH_RES_DIR}/${bench_name}/${bench_name}${NAME_EXTENSION}.txt
    echo "# Starting bandwidth: APU=${APU_BANDWIDTH}, FPGA=${FPGA_BANDWIDTH}, RPU=${RPU_BANDWIDTH}" >> ${TACLEBENCH_RES_DIR}/${bench_name}/${bench_name}${NAME_EXTENSION}.txt
    echo "iteration,apu_bandwidth,fpga_bandwidth,rpu_bandwidth,time,in_target" >> ${TACLEBENCH_RES_DIR}/${bench_name}/${bench_name}${NAME_EXTENSION}.txt

    for ((rep=0; rep<=${REPETITIONS}; rep++)); do
        #Apply temporal regulation
        echo "Applying temporal regulation -R ${RPU_BANDWIDTH} -F ${FPGA_BANDWIDTH} -A ${APU_BANDWIDTH}"
        bash ${UTILITY_DIR}/apply_temp_reg.sh -R ${RPU_BANDWIDTH} -F ${FPGA_BANDWIDTH} -A ${APU_BANDWIDTH} -r -f -a
        echo "Applied"

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
        
        # Get time value
        time=$(devmem ${shm})
        time=`printf "%d" ${time}`

        # Clean Shared Memory
        devmem ${shm} 32 0x00000000
        # Destroy RPU Cell
        jailhouse cell destroy inmate-demo-${core}
        wait
        usleep 100000

        if [[ $rep -eq 0 ]]; then
            baseline=$time
            echo "BASELINE = ${baseline}"
            RPU_BANDWIDTH=$TMP_RPU_BANDWIDTH
            FPGA_BANDWIDTH=$TMP_FPGA_BANDWIDTH
            APU_BANDWIDTH=$TMP_APU_BANDWIDTH
            continue
        fi

        # echo "$baseline * $TARGET_SLOWDOWN > $time"
        # echo "$baseline * $TARGET_SLOWDOWN > $time" | bc -l
        in_target=`echo "$baseline * $TARGET_SLOWDOWN > $time" | bc -l`
        echo "BELOW_TARGET_SLOWDOWN: ${in_target}" 

        # Write results to the file
        # printf "%d\n" ${time} >> ${TACLEBENCH_RES_DIR}/${bench_name}/${bench_name}${NAME_EXTENSION}.txt
        printf "%d,%.f,%.f,%.f,%d,%d\n" ${rep} ${APU_BANDWIDTH} ${FPGA_BANDWIDTH} ${RPU_BANDWIDTH} ${time} ${in_target} >> ${TACLEBENCH_RES_DIR}/${bench_name}/${bench_name}${NAME_EXTENSION}.txt
        printf "TIME: %d; " ${time} 

        if [[ $in_target -eq 0 ]]; then
            LAST_RPU_BANDWIDTH=0
            LAST_FPGA_BANDWIDTH=0
            LAST_APU_BANDWIDTH=0
        fi

        # echo "( ${RPU_BANDWIDTH} + ${LAST_RPU_BANDWIDTH} ) / 2"
        TMP_RPU_BANDWIDTH=`echo "( ${RPU_BANDWIDTH} + ${LAST_RPU_BANDWIDTH} ) / 2" | bc -l`
        TMP_FPGA_BANDWIDTH=`echo "( ${FPGA_BANDWIDTH} + ${LAST_FPGA_BANDWIDTH} ) / 2" | bc -l`
        TMP_APU_BANDWIDTH=`echo "( ${APU_BANDWIDTH} + ${LAST_APU_BANDWIDTH} ) / 2" | bc -l`

        LAST_RPU_BANDWIDTH=$RPU_BANDWIDTH
        LAST_FPGA_BANDWIDTH=$FPGA_BANDWIDTH
        LAST_APU_BANDWIDTH=$APU_BANDWIDTH

        RPU_BANDWIDTH=$TMP_RPU_BANDWIDTH
        FPGA_BANDWIDTH=$TMP_FPGA_BANDWIDTH
        APU_BANDWIDTH=$TMP_APU_BANDWIDTH

    done

    break
done
