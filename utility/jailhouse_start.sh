#!/bin/bash

#WARNINGS: 
#      configure with the right .cell
#      Set the variable JAILHOUSE_DIR to the jailhouse directory
source /etc/profile
ROOT_CELL="zynqmp-kv260.cell"

# Check if the firmware directory exists
if [ -d "/lib/firmware"  ]; then
       echo "firmware directory exists!"
else
	mkdir -p /lib/firmware
fi

# Clean up if enabled
jailhouse disable
rmmod jailhouse

# Copy the hypervisor image in the firmware directory
cp ${JAILHOUSE_DIR}/hypervisor/jailhouse.bin /lib/firmware/

# Insert the jailhouse module
insmod  ${JAILHOUSE_DIR}/driver/jailhouse.ko

# Start the hypervisor
jailhouse enable ${JAILHOUSE_DIR}/configs/arm64/${ROOT_CELL}