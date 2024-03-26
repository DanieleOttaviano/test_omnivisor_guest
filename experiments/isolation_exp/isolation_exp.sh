#!/bin/bash

source /etc/profile
echo $$ >> /sys/fs/cgroup/cpuset/test/cgroup.procs

usage() {
	echo -e "Usage: $0 \r\n \
  		This script launch the Isolation test on the selected processor:\r\n \
    		[-c <core under isolation test> (RPU, RISCV)]\r\n \
    		[-n <Test Name>]\r\n \
    		[-h help]" 1>&2
	 exit 1
}

#DIRECTORIES
ISOLATION_EXP_PATH="/root/tests/omnivisor/experiments/isolation_exp"
INMATES_PATH=${ISOLATION_EXP_PATH}/inmates/
UTILITY_PATH="/root/tests/omnivisor/utility"
OUTPUT_LOG="/dev/null" #"/tmp/boot_time.log"

TEST_DURATION=20 # seconds

while getopts "c:n:h" o; do
    case "${o}" in
        c)
			core=${OPTARG}
            ;;
        n)
            TEST_NAME=${OPTARG}
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
echo "Test name: ${TEST_NAME} (duration: ${TEST_DURATION}s)"

# Remove kernel prints
echo "1" > /proc/sys/kernel/printk

## START TEST
# Start core under isolation test
jailhouse cell create ${INMATES_PATH}/${core}/zynqmp-kv260-${core}-inmate-demo.cell >> ${OUTPUT_LOG} 2>&1
if [[ "${core}" == "RPU" ]]; then
    jailhouse cell load inmate-demo-${core} ${INMATES_PATH}/${core}/${core}-isolation-demo_tcm.bin -a 0xffe00000 ${INMATES_PATH}/${core}/${core}-isolation-demo.bin >> ${OUTPUT_LOG} 2>&1
elif [[ "${core}" == "RISCV" ]]; then
    jailhouse cell load inmate-demo-${core} ${INMATES_PATH}/${core}/${core}-isolation-demo.bin >> ${OUTPUT_LOG} 2>&1
fi
jailhouse cell start inmate-demo-${core} >> ${OUTPUT_LOG} 2>&1

