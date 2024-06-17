#!/bin/bash

source /etc/profile
source "$(dirname "$0")/../utility/default_directories.sh"

DEMO_INMATES_PATH="$(dirname "$0")/inmates"

# CGROUP="/sys/fs/cgroup/cpuset/demo"
OUTPUT_LOG="/dev/null" #"/tmp/boot_time.log"

# # Check if cgroup exists, otherwise create it
# if [ ! -d ${CGROUP}/ ]; then 
#     mkdir ${CGROUP}
#     echo 0 > ${CGROUP}/cpuset.cpus
#     echo 0 > ${CGROUP}/cpuset.mems
# fi

# echo $$ >> ${CGROUP}/cgroup.procs

usage() {
	echo -e "\
Usage: $0 [-c RPU|RISCV]
This script launch the Isolation test on the selected processor:
    [-c <core under isolation test> (RPU, RISCV)]
    [-h help]" 1>&2
    exit 1
}

while getopts "c:dlh" o; do
    case "${o}" in
        c)
			core=${OPTARG}
            ;;
        d)
            action="Destroy"
            ;;
        l)
            action="Load"
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

# Check Inputs
if [[ $action != "Load" && $action != "Destroy" ]]; then
	echo "Error: Invalid action: ${action}"
    echo "Valid actions: Load [-l], Destroy [-d]"
	usage
	exit 1
fi

# Remove kernel prints
echo "1" > /proc/sys/kernel/printk

if [[ $action == "Load" ]]; then
    # Start core under isolation test
    jailhouse cell create ${DEMO_INMATES_PATH}/${core}/zynqmp-kv260-${core}-inmate-demo.cell
    if [[ "${core}" == "RPU" ]]; then
        jailhouse cell load inmate-demo-${core} ${DEMO_INMATES_PATH}/${core}/baremetal-demo_tcm.bin -a 0xffe00000 ${DEMO_INMATES_PATH}/${core}/baremetal-demo.bin
    elif [[ "${core}" == "RISCV" ]]; then
        jailhouse cell load inmate-demo-${core} ${DEMO_INMATES_PATH}/${core}/baremetal-demo.bin
    fi
    jailhouse cell start inmate-demo-${core}
else
    jailhouse cell destroy inmate-demo-${core} >> ${OUTPUT_LOG} 2>&1
fi

jailhouse cell list

