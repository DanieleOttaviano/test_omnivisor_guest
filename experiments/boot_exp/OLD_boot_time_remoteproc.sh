#!/bin/bash

usage() {
	echo -e "Usage: $0 \r\n \
  		This script launch the Boot test using remoteproc:\r\n \
    		[-r <repetitions>]\r\n \
    		[-h help]" 1>&2
	 exit 1
}

UTILITY_PATH="/root/tests/omnivisor/utility"
BOOT_RESULTS_PATH="/root/tests/omnivisor/results/boot_results"
REMOTEPROC0_PATH="/sys/class/remoteproc/remoteproc0"

# Image sizes in Megabytes
image_sizes=(1 10 20 30 40 50 60 70 80 90)
# Shared Memory Location
SHARED_MEM_ADDR=0x46d00000
# Timer limit value
limit=0xFFFFFFFF
# Timer Frequency 
frequency=100000

while getopts "r:h" o; do
    case "${o}" in
        r)
			repetitions=${OPTARG}
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
if [[ $repetitions -lt 1 ]]; then
	echo "Error: Invalid number of repetitions specified."
	usage
	exit 1
fi

# Remove kernel prints
echo "1" > /proc/sys/kernel/printk

# Move in lib/firmware directory
cd /lib/firmware 
# Stop RPU Cell if running
echo stop > ${REMOTEPROC0_PATH}/state
wait 

# Clean Shared Memory
devmem ${SHARED_MEM_ADDR} 32 0x00000000

# Create the directory for the results and clean it if already exist
mkdir -p ${BOOT_RESULTS_PATH}/boot_remoteproc
rm -f ${BOOT_RESULTS_PATH}/boot_remoteproc/*
# Save old results
mv ${BOOT_RESULTS_PATH}/boot_remoteproc/* ${BOOT_RESULTS_PATH}/OLD_boot_remoteproc/
# Clean results
rm -f ${BOOT_RESULTS_PATH}/boot_remoteproc/*

echo "Launching Boot Time Test on RPU using remoteproc (${repetitions} repetitions)"
echo ""

for size in "${image_sizes[@]}"; do
	# Retrieve image from the SD card
	cat RPU-demo-${size}Mb.elf > /dev/null
	wait
	
	for ((rep=0; rep<${repetitions}; rep++))
	do

		## TEST
		# Init Time	
		hex_init_time=$(devmem 0xFF250000)
		# Load and Start RPU Cell
		echo RPU-demo-${size}Mb.elf  > ${REMOTEPROC0_PATH}/firmware
		echo start > ${REMOTEPROC0_PATH}/state		
		# Wait for the RPU to boot
		while [ "$(devmem 0x46d00000)" == "0x00000000" ]; do
			:
		done
		# Boot Time
		hex_boot_time=$(devmem 0x46d00000)	


		## CLEAN UP
		# Clean Shared Memory
		devmem ${SHARED_MEM_ADDR} 32 0x00000000
		# Stop RPU Cell
		echo stop > ${REMOTEPROC0_PATH}/state

		## SAVE RESULTS
		# Convert hexadecimal values to decimal
		dec_init_time=$((hex_init_time))
		dec_boot_time=$((hex_boot_time))
		# Save decimal values in respective files
		echo "$dec_init_time $size" >> ${BOOT_RESULTS_PATH}/boot_remoteproc/init_time.txt
		echo "$dec_boot_time $size" >> ${BOOT_RESULTS_PATH}/boot_remoteproc/boot_time.txt

		# Print boot time
		if [[ $dec_boot_time -gt $dec_init_time ]]; then
			time=$(($dec_boot_time - $dec_init_time))
		else
			time=$(($dec_boot_time + ($limit - $dec_init_time)))
		fi
		time=$(($time / $frequency))
		echo "Image size: ${size}Mb | Repetition: $(( ${rep} + 1 )) | Boot Time: ${time}ms"
	done
done

# Re-enable kernel prints
echo "7" > /proc/sys/kernel/printk

for (( i=0; i<10; i++ ))
do
	echo "Finish!"
	sleep 1
done
