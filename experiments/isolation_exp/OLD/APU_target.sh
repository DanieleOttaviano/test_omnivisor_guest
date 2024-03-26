#!/bin/bash

# Check if three arguments are provided
if [ $# -ne 3 ]; then
    echo "Error: Three arguments required. Provide TEST_NAME, APP, and QOS."
    exit 1
fi

TEST_NAME="$1"
APP="$2"
QOS="$3"

# SLEEP TIME BEFORE INTERFERENCE
TEST_DURATION=20
SOLO_TIME=2
INTERFERENCE_TIME=$((TEST_DURATION - SOLO_TIME))
# DIRECTORIES
RPROC_SCRIPT_PATH="/root/scripts_remoteproc"
JAIL_SCRIPT_PATH="/root/scripts_jailhouse_kria"
TARGET_EXP_PATH="/root/tests/omnivisor/isolation_exp"
UTILITY_PATH="/root/tests/omnivisor/utility"


echo "Test name: ${TEST_NAME}"
echo "Application: ${APP}"
echo "QoS: ${QOS}"


## START TEST
if [[ "${APP}" == "bitflip" ]]; then
    # Stop the core if running and start RPU app using remoteproc
    bash ${RPROC_SCRIPT_PATH}/remoteproc_stop.sh
    bash ${RPROC_SCRIPT_PATH}/remoteproc_launch.sh
    sleep ${SOLO_TIME}
    
    # Start APU bitflip
    ${TARGET_EXP_PATH}/flip_bit & PID=$! 
    sleep ${INTERFERENCE_TIME}
    
    # Disable remoteproc
    bash ${RPROC_SCRIPT_PATH}/remoteproc_stop.sh

else # APP is membomb

    # Start RPU0 Application using the Omnivisor (Jailhouse) and check for QoS
    bash ${UTILITY_PATH}/jailhouse_start.sh
    if [[ "${QOS}" -eq "1" ]]; then
        # Apply QoS regulation
        bash ${UTILITY_PATH}/apply_temp_reg.sh -a
    fi
    bash ${JAIL_SCRIPT_PATH}/relaunch_RPU_cell.sh
    sleep ${SOLO_TIME}

    # Start APU membomb application on all the cores
    ${TARGET_EXP_PATH}/bandwidth -l1 -c0 -p 0 -d 0 -b "-a write -m 4096 -i12" & 
    ${TARGET_EXP_PATH}/bandwidth -l1 -c1 -p 0 -d 0 -b "-a write -m 4096 -i12" & 
    ${TARGET_EXP_PATH}/bandwidth -l1 -c2 -p 0 -d 0 -b "-a write -m 4096 -i12" & 
    ${TARGET_EXP_PATH}/bandwidth -l1 -c3 -p 0 -d 0 -b "-a write -m 4096 -i12" &
    sleep ${INTERFERENCE_TIME} 

    # Disable QoS
    if [[ "${QOS}" -eq "1" ]]; then
        jailhouse qos disable
    fi
    # Disable jailhouse
    jailhouse disable
fi

## CLEAN UP
# Stop both APU applications
killall bandwidth

## SAVE RESULTS
bash ${UTILITY_PATH}/save_shm.sh ${TEST_NAME}
# FINISH!
for (( i=0; i<10; i++ ))
do
	echo "Finish!"
	sleep 1
done

