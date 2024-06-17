#!/bin/bash

# source /etc/profile
# echo $$ >> /sys/fs/cgroup/cpuset/test/cgroup.procs

# pwd
source "$(dirname "$0")/../../utility/default_directories.sh"

# REGISTERS
TRAFFIC_GENERATOR_1=0x80010000
TRAFFIC_GENERATOR_2=0x80020000
TRAFFIC_GENERATOR_3=0x80030000
SHARED_MEM_ADDR=0x46d00000

TEST_DURATION=20 # seconds
SOLO_TIME=2 # seconds
FULL_INTERFERENCE_TIME=$(( TEST_DURATION - SOLO_TIME ))
SPAT_ISOL=0

while getopts "c:d:h:S:" o; do
    case "${o}" in
        c)
			core=${OPTARG}
            TEST_NAME=$core
            ;;
        d)
			disturb=${OPTARG}
            TEST_NAME=${TEST_NAME}_${disturb}
            if [[ "${disturb}" == "NONE" ]]; then
                SOLO_TIME=${TEST_DURATION}
            fi
            if [[ "${disturb}" == "ALL" ]]; then
                SOLO_TIME=4
                FULL_INTERFERENCE_TIME=$(( TEST_DURATION - (SOLO_TIME * 4) ))
            fi
            ;;
        S)
            SPAT_ISOL=${OPTARG}
			TEST_NAME=${TEST_NAME}_spt
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
if [[ $disturb != "NONE" && $disturb != "APU" && $disturb != "RPU1" && $disturb != "FPGA" && $disturb != "ALL" ]]; then
	echo "Error: Invalid disturb source specified: ${disturb}"
    echo "Valid sources: NONE, APU, RPU1, FPGA, ALL"
	usage
	exit 1
fi

# Time without interference
sleep ${SOLO_TIME}

# Start the interferences
if [[ $disturb == "APU" || $disturb == "ALL" ]]; then
    echo "Starting APU membomb"
    if [[ "${SPAT_ISOL}" -eq "0" ]]; then
        # Without spatial isolation the APU would crash the system
        # Therefore to save the experiemnt we do not start the APU
        # ssh root@${IP} "${INMATES_PATH}/APU/flip_bit"
        :
    else
        # Start APU membomb
        ${ISOLATION_INMATES_PATH}/APU/bandwidth -l1 -c1 -p 0 -d 0 -b "-a write -m 4096 -i12" &
        ${ISOLATION_INMATES_PATH}/APU/bandwidth -l1 -c2 -p 0 -d 0 -b "-a write -m 4096 -i12" &
        ${ISOLATION_INMATES_PATH}/APU/bandwidth -l1 -c3 -p 0 -d 0 -b "-a write -m 4096 -i12" &
    fi

    if [[ $disturb == "ALL" ]]; then
        sleep ${SOLO_TIME}
    else
        sleep ${FULL_INTERFERENCE_TIME}
    fi
fi
if [[ $disturb == "RPU1" || $disturb == "ALL" ]]; then
    # Start RPU1 membomb
    echo "Starting RPU1 membomb"
    cd /lib/firmware
    echo RPU1-${core}-membomb-demo.elf > /sys/class/remoteproc/remoteproc1/firmware
    echo start > /sys/class/remoteproc/remoteproc1/state

    if [[ $disturb == "ALL" ]]; then
        sleep ${SOLO_TIME}
    else
        sleep ${FULL_INTERFERENCE_TIME}
    fi
fi
if [[ $disturb == "FPGA" || $disturb == "ALL" ]]; then
    # Start traffic generators
    echo "Starting FPGA Traffic Generator 1"
    if [[ $core == "RPU" ]]; then
        devmem ${TRAFFIC_GENERATOR_1} 64 1
    elif [[ $core == "RISCV" ]]; then
        devmem ${TRAFFIC_GENERATOR_2} 64 1
    fi

    # If ALL power on another traffic generator
    if [[ $disturb == "ALL" ]]; then
        sleep ${SOLO_TIME}
        echo "Starting FPGA Traffic Generator 2"
        devmem ${TRAFFIC_GENERATOR_3} 64 1
        sleep ${SOLO_TIME}
    else
        :
        sleep ${FULL_INTERFERENCE_TIME}
    fi
fi

## STOP TEST
if [[ $disturb == "APU" || $disturb == "ALL" ]]; then
    # Stop APU membomb
    echo "Stopping APU membomb"
    killall bandwidth
fi
if [[ $disturb == "RPU1" || $disturb == "ALL" ]]; then
    # Stop RPU1 membomb
    echo "Stopping RPU1 membomb"
    echo stop > /sys/class/remoteproc/remoteproc1/state
fi
if [[ $disturb == "FPGA" || $disturb == "ALL" ]]; then
    # Stop traffic generators
    echo "Stopping FPGA Traffic Generators"
    devmem ${TRAFFIC_GENERATOR_1} 64 0
    devmem ${TRAFFIC_GENERATOR_2} 64 0
    devmem ${TRAFFIC_GENERATOR_3} 64 0
fi