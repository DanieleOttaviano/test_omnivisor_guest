#!/bin/bash

#WARNINGS: 
#      Set the variable JAILHOUSE_DIR to the jailhouse directory
source /etc/profile
JAILHOUSE="$(dirname "$0")/jailhouse"

usage() {
	echo -e "\
Usage: $0 [-e] [-d] [-h]
This script change Jailhouse status:
    [-e Enable Jailhouse]
    [-s Enable spatial isolation (ignored if not with -e)]
    [-d Disable Jailhouse]
    [-t <BANDWIDTH> Enable temporal isolation with given bandwidth]
    [-T Disable temporal isolation]
    [-h help]" 1>&2
    exit 1
}

ENABLE=0
DISABLE=0
SPATIAL=0
ENABLE_TEMPORAL=0
DISABLE_TEMPORAL=0

while getopts "dehst:T" o; do
    case "${o}" in
        d)
			DISABLE=1
            ;;
        e)
			ENABLE=1
            ;;
        h)
            usage
            ;;
        s)
            SPATIAL=1
            ;;
        t)
            ENABLE_TEMPORAL=1
            # BANDWIDTH=$OPTARG
            r_qos_value=`echo "\`echo "2^31 / 10^9 * ${OPTARG}" | bc -l\` / 1" | bc`
            echo "RPU 1 QOS VALUE: ${r_qos_value}"
            f_qos_value=`echo "\`echo "2^31 / 10^9 * ${OPTARG}" | bc -l\` / 1" | bc`
            echo "FPGA QOS VALUE: ${f_qos_value}"
            a_memguard_value=`echo "\`echo "${OPTARG} * 1000 / 64" | bc -l\` / 1" | bc`
            echo "APU MEMGUARD W VALUE: ${a_memguard_value}"
            ;;
        T)
            DISABLE_TEMPORAL=1
            # r_qos_value=`echo "\`echo "2^31 / 10^9 * 10000" | bc -l\` / 1" | bc`
            # echo "RPU 1 QOS VALUE: ${r_qos_value}"
            # f_qos_value=`echo "\`echo "2^31 / 10^9 * 10000" | bc -l\` / 1" | bc`
            # echo "FPGA QOS VALUE: ${f_qos_value}"
            a_memguard_value=`echo "\`echo "10000 * 1000 / 64" | bc -l\` / 1" | bc`
            # echo "APU MEMGUARD W VALUE: ${a_memguard_value}"
            ;;
        *)
            usage
            ;;
    esac
done

# Check Inputs
if [[ $((${ENABLE} + ${DISABLE} + ${ENABLE_TEMPORAL} + ${DISABLE_TEMPORAL})) -ne 1 ]]; then
	echo "Exactly one option among [-e], [-d], [-t] and [-T] has to be provided"
	usage
	exit 1
fi

if [[ "${ENABLE}" == 1 ]]; then
    # Check if the firmware directory exists
    if [ ! -d "/lib/firmware"  ]; then
    #        echo "firmware directory exists!"
    # else
        mkdir -p /lib/firmware
    fi

    # Clean up if enabled
    jailhouse disable
    rmmod jailhouse

    if [[ "${SPATIAL}" == 1 ]]; then
        echo "Starting jailhouse with spatial"
        cp ${JAILHOUSE}/hypervisor/jailhouse_xmpu.bin /lib/firmware/jailhouse.bin
    else
        echo "Starting jailhouse without spatial"
        cp ${JAILHOUSE}/hypervisor/jailhouse_noxmpu.bin /lib/firmware/jailhouse.bin
    fi

    # Insert the jailhouse module
    insmod  ${JAILHOUSE}/driver/jailhouse.ko

    # Start the hypervisor
    jailhouse enable ${JAILHOUSE}/root_cell/zynqmp-kv260.cell
elif [[ "${DISABLE}" == 1 ]]; then
    jailhouse disable
    rmmod jailhouse  
elif [[ "${ENABLE_TEMPORAL}" == 1 ]]; then
    jailhouse qos rpu1:ar_b=1,aw_b=1,ar_r=${r_qos_value},aw_r=${r_qos_value}              # RPU-1 on ZCU102
    jailhouse qos intfpdsmmutbu4:ar_b=1,aw_b=1,ar_r=${f_qos_value},aw_r=${f_qos_value}    # Traffic Generator 1 and 2 on FPGA
    jailhouse qos intfpdsmmutbu5:ar_b=1,aw_b=1,ar_r=${f_qos_value},aw_r=${f_qos_value}    # Traffic Generator 3 on FPGA
    jailhouse memguard 1 1000 ${a_memguard_value} w
    jailhouse memguard 2 1000 ${a_memguard_value} w
    jailhouse memguard 3 1000 ${a_memguard_value} w    
elif [[ "${DISABLE_TEMPORAL}" == 1 ]]; then
    jailhouse qos disable
    jailhouse memguard 1 1000 ${a_memguard_value} w
    jailhouse memguard 2 1000 ${a_memguard_value} w
    jailhouse memguard 3 1000 ${a_memguard_value} w
fi