#!/bin/bash

usage() {
	echo -e "Usage: $0 \r\n \
  		This script launch the Boot test on the selected processor:\r\n \
    		[-r <repetitions>]\r\n \
    		[-c <core> (APU, RPU, RISCV)]\r\n \
    		[-h help]" 1>&2
	 exit 1
}

#DIRECTORIES
source "$(dirname "$0")/../../utility/default_directories.sh"

OUTPUT_LOG="/dev/null" #"/tmp/boot_time.log"

# CELL NAME
ROOT_CELL="zynqmp-kv260.cell"

# Image sizes in Megabytes
image_sizes=(1 10 20 30 40 50 60 70 80 90)
# Shared Memory Location
SHARED_MEM_ADDR=0x46d00000
# Timer limit value
limit=0xFFFFFFFF
# Timer Frequency 
frequency=100000


while getopts "r:c:h" o; do
    case "${o}" in
        r)
			repetitions=${OPTARG}
            ;;
        c)
			core=${OPTARG}
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
	echo "Error: Invalid number of repetitions specified: $repetitions"
	usage
	exit 1
fi
if [[ $core != "APU" && $core != "RPU" && $core != "RISCV" ]]; then
	echo "Error: Invalid core specified: $core"
	echo "Valid cores: APU, RPU, RISCV"
	usage
	exit 1
fi

# Remove kernel prints
echo "1" > /proc/sys/kernel/printk
# Clean tmp file for the log
echo "" > ${OUTPUT_LOG}

# Start the Hypervisor (Remove if already there)
${UTILITY_DIR}/jailhouse_start.sh >> ${OUTPUT_LOG} 2>&1

# Clean Shared Memory
devmem ${SHARED_MEM_ADDR} 32 0x00000000

# Create the directory for the results and Old results
mkdir -p ${BOOT_RESULTS_PATH}/boot_${core}
mkdir -p ${BOOT_RESULTS_PATH}/OLD_boot_${core}
# Save old results
mv ${BOOT_RESULTS_PATH}/boot_${core}/* ${BOOT_RESULTS_PATH}/OLD_boot_${core}/
# Clean results
rm -f ${BOOT_RESULTS_PATH}/boot_${core}/*

echo "Launching Boot Time Test on ${core} (${repetitions} repetitions)"
echo ""

# Repete the test for each image size
for size in "${image_sizes[@]}"; do
	for ((rep=0; rep<${repetitions}; rep++)); do

		# Retrieve image from the SD card
		cat ${BOOT_INMATES_PATH}/${core}/${core}-demo-${size}Mb.bin > /dev/null
		if [[ $core == "RPU" ]]; then
			cat ${BOOT_INMATES_PATH}/${core}/${core}-demo_tcm.bin > /dev/null
		fi
		wait

		## TEST
		# Init Time	
		hex_init_time=$(devmem 0xFF250000)
		
		# Create Cell
		jailhouse cell create ${BOOT_INMATES_PATH}/${core}/zynqmp-kv260-${core}-inmate-demo.cell >> ${OUTPUT_LOG} 2>&1	
		hex_create_time=$(devmem 0xFF250000)
		
		# Load Cell
		if [[ $core == "RPU" ]]; then
			jailhouse cell load inmate-demo-${core} ${BOOT_INMATES_PATH}/${core}/${core}-demo_tcm.bin -a 0xffe00000 ${BOOT_INMATES_PATH}/${core}/${core}-demo-${size}Mb.bin >> ${OUTPUT_LOG} 2>&1
		else
			jailhouse cell load inmate-demo-${core} ${BOOT_INMATES_PATH}/${core}/${core}-demo-${size}Mb.bin >> ${OUTPUT_LOG} 2>&1
		fi
		
		hex_load_time=$(devmem 0xFF250000)
		
		# Start Cell
		jailhouse cell start inmate-demo-${core} >> ${OUTPUT_LOG} 2>&1
		hex_start_time=$(devmem 0xFF250000)
		
		# Wait for the core to boot
		usleep 300000
		while [ "$(devmem 0x46d00000)" == "0x00000000" ];do
			usleep 300000
		done 
		hex_boot_time=$(devmem 0x46d00000)	
		

		## CLEAN UP
		# Clean Shared Memory
		devmem ${SHARED_MEM_ADDR} 32 0x00000000
		# Destroy RPU Cell
		jailhouse cell destroy inmate-demo-${core} >> ${OUTPUT_LOG} 2>&1

		## SAVE RESULTS
		# Convert hexadecimal values to decimal
		dec_init_time=$((hex_init_time))
		dec_create_time=$((hex_create_time))
		dec_load_time=$((hex_load_time))
		dec_start_time=$((hex_start_time))
		dec_boot_time=$((hex_boot_time))
		# Save decimal values in respective files
		echo "$dec_init_time $size" 	>> ${BOOT_RESULTS_PATH}/boot_${core}/init_time.txt
		echo "$dec_create_time $size" 	>> ${BOOT_RESULTS_PATH}/boot_${core}/create_time.txt
		echo "$dec_load_time $size" 	>> ${BOOT_RESULTS_PATH}/boot_${core}/load_time.txt
		echo "$dec_start_time $size" 	>> ${BOOT_RESULTS_PATH}/boot_${core}/start_time.txt
		echo "$dec_boot_time $size" 	>> ${BOOT_RESULTS_PATH}/boot_${core}/boot_time.txt
		wait

		# Print boot time
		if [[ $dec_boot_time -gt $dec_init_time ]]; then
			time=$(($dec_boot_time - $dec_init_time))
		else
			time=$(($dec_boot_time + ($limit - $dec_init_time)))
		fi
		time=$(($time / $frequency))
		echo "Image size: ${size}Mb | Repetition: $(( ${rep} + 1 )) | Boot Time: ${time}ms"
		wait
	done
done

# Disable jailhouse
jailhouse disable >> ${OUTPUT_LOG}


# Re-enable kernel prints
echo "7" > /proc/sys/kernel/printk

echo "Finish!"
