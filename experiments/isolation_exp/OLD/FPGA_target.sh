#!/bin/bash

# Check if three arguments are provided
if [ $# -ne 2 ]; then
    echo "Error: Three arguments required. Provide TEST_NAME and QOS."
    exit 1
fi

TEST_NAME="$1"
QOS="$2"

# REGISTERS
tg=0x80000000
shm=0x46d00000
# SLEEP TIME BEFORE INTERFERENCE
TEST_DURATION=20
SOLO_TIME=2
INTERFERENCE_TIME=$((TEST_DURATION - SOLO_TIME))
# DIRECTORIES
RPROC_SCRIPT_PATH="/root/scripts_remoteproc"
JAIL_SCRIPT_PATH="/root/scripts_jailhouse_kria"
TARGET_EXP_PATH="/root/tests/omnivisor/spatial_isolation_exp"
UTILITY_PATH="/root/tests/omnivisor/utility"


echo "Test name: ${TEST_NAME}"
echo "QoS: ${QOS}"

## START TEST
# Start RPU0 Application
bash ${UTILITY_PATH}/jailhouse_start.sh
if [[ "${QOS}" -eq "1" ]]; then
    # Apply QoS regulation
    bash ${UTILITY_PATH}/apply_temp_reg.sh -f
fi
bash ${JAIL_SCRIPT_PATH}/relaunch_RPU_cell.sh

sleep ${SOLO_TIME}

# Start the FPGA traffic generator
devmem ${tg} 64 1

sleep ${INTERFERENCE_TIME} 

## CLEAN UP
# Stop traffic generator
devmem ${tg} 64 0
# Disable QoS
if [[ "${QOS}" -eq "1" ]]; then
    jailhouse qos disable
fi
# Disable jailhouse
jailhouse disable

## SAVE RESULTS
bash ${UTILITY_PATH}/save_shm.sh ${TEST_NAME}
# FINISH!
for (( i=0; i<10; i++ ))
do
	echo "Finish!"
	sleep 1
done

