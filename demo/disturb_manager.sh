#!/bin/bash


# pwd
source "$(dirname "$0")/../utility/default_directories.sh"

# REGISTERS
TRAFFIC_GENERATOR_1=0x80010000
TRAFFIC_GENERATOR_2=0x80020000
TRAFFIC_GENERATOR_3=0x80030000
SHARED_MEM_ADDR=0x46d00000

while getopts "a:d:h" o; do
    case "${o}" in
        a)
            action=${OPTARG}
            ;;
        d)
			disturb=${OPTARG}
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
if [[ $action != "Enable" && $action != "Disable" ]]; then
	echo "Error: Invalid action specified: ${action}"
    echo "Valid actions: Enable, Disable"
	usage
	exit 1
fi  

if [[ $disturb != "NONE" && $disturb != "APU" && $disturb != "RPU1" && $disturb != "FPGA" ]]; then
	echo "Error: Invalid disturb source specified: ${disturb}"
    echo "Valid sources: NONE, APU, RPU1, FPGA, ALL"
	usage
	exit 1
fi

if [[ $action == "Enable" ]]; then
    # Start the interferences
    if [[ $disturb == "APU" ]]; then
        echo "Starting APU membomb"
        ${ISOLATION_INMATES_PATH}/APU/bandwidth -l1 -c1 -p 0 -d 0 -b "-a write -m 4096 -i12" &
        ${ISOLATION_INMATES_PATH}/APU/bandwidth -l1 -c2 -p 0 -d 0 -b "-a write -m 4096 -i12" &
        ${ISOLATION_INMATES_PATH}/APU/bandwidth -l1 -c3 -p 0 -d 0 -b "-a write -m 4096 -i12" &
    fi
    if [[ $disturb == "RPU1" ]]; then
        # Start RPU1 membomb
        echo "Starting RPU1 membomb"
        cd /lib/firmware
        echo RPU1-membomb-demo.elf > /sys/class/remoteproc/remoteproc1/firmware
        echo start > /sys/class/remoteproc/remoteproc1/state
    fi
    if [[ $disturb == "FPGA" ]]; then
        # Start traffic generators
        echo "Starting FPGA Traffic Generators"
        devmem ${TRAFFIC_GENERATOR_1} 64 1
        devmem ${TRAFFIC_GENERATOR_2} 64 1
        devmem ${TRAFFIC_GENERATOR_3} 64 1
    fi
else
    ## STOP TEST
    if [[ $disturb == "APU" ]]; then
        # Stop APU membomb
        echo "Stopping APU membomb"
        killall bandwidth
    fi
    if [[ $disturb == "RPU1" ]]; then
        # Stop RPU1 membomb
        echo "Stopping RPU1 membomb"
        echo stop > /sys/class/remoteproc/remoteproc1/state
    fi
    if [[ $disturb == "FPGA" ]]; then
        # Stop traffic generators
        echo "Stopping FPGA Traffic Generators"
        devmem ${TRAFFIC_GENERATOR_1} 64 0
        devmem ${TRAFFIC_GENERATOR_2} 64 0
        devmem ${TRAFFIC_GENERATOR_3} 64 0
    fi
fi