#!/bin/bash

# Check if three arguments are provided
if [ $# -ne 2 ]; then
    echo "Error: Three arguments required. Provide TEST_NAME and QOS."
    exit 1
fi

TEST_NAME="$1"
QOS="$2"

# REGISTERS
tg1=0x80000000
tg2=0x80010000
tg3=0x80020000
shm=0x46d00000
# SLEEP TIME BEFORE INTERFERENCE
TEST_DURATION=20
SOLO_TIME=3
FULL_INTERFERENCE_TIME=$((TEST_DURATION - (SOLO_TIME * 5)))

# DIRECTORIES
RPROC_SCRIPT_PATH="/root/scripts_remoteproc"
JAIL_SCRIPT_PATH="/root/scripts_jailhouse_kria"
TARGET_EXP_PATH="/root/tests/omnivisor/isolation_exp"
UTILITY_PATH="/root/tests/omnivisor/utility"


echo "Test name: ${TEST_NAME}"
echo "QoS: ${QOS}"

## START TEST
# Start RPU0 cell
bash ${UTILITY_PATH}/jailhouse_start.sh
if [[ "${QOS}" -eq "1" ]]; then
    # Apply QoS regulation
    bash ${UTILITY_PATH}/apply_temp_reg.sh -a -r -f
    # bash ${UTILITY_PATH}/apply_temp_reg.sh -r
    # bash ${UTILITY_PATH}/apply_temp_reg.sh -f
fi
bash ${JAIL_SCRIPT_PATH}/relaunch_RPU_cell.sh
sleep ${SOLO_TIME}

# Start APU membomb bandwidth
${TARGET_EXP_PATH}/bandwidth -l1 -c0 -p 0 -d 0 -b "-a write -m 4096 -i12" & 
${TARGET_EXP_PATH}/bandwidth -l1 -c1 -p 0 -d 0 -b "-a write -m 4096 -i12" & 
${TARGET_EXP_PATH}/bandwidth -l1 -c2 -p 0 -d 0 -b "-a write -m 4096 -i12" & 
${TARGET_EXP_PATH}/bandwidth -l1 -c3 -p 0 -d 0 -b "-a write -m 4096 -i12" &
sleep ${SOLO_TIME}

# Start RPU1 Application using remoteproc
bash ${RPROC_SCRIPT_PATH}/remoteproc1_stop.sh
bash ${RPROC_SCRIPT_PATH}/remoteproc1_launch.sh
sleep ${SOLO_TIME}

# Gradually start the FPGA traffic generators
devmem ${tg1} 64 1
sleep ${SOLO_TIME}
devmem ${tg2} 64 1
sleep ${SOLO_TIME}
devmem ${tg3} 64 1
sleep ${FULL_INTERFERENCE_TIME}

## CLEAN UP
# Stop APU
killall bandwidth
# Stop RPU1
bash ${RPROC_SCRIPT_PATH}/remoteproc1_stop.sh
# Stop traffic generators
devmem ${tg1} 64 0
devmem ${tg2} 64 0
devmem ${tg3} 64 0
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
