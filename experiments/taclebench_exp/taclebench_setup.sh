# BOARD_TESTS_PATH="/root/tests"
# BOARD_JAILHOUSE_PATH="/root/jailhouse"
# BOARD_JAIL_SCRIPT_PATH="/root/scripts_jailhouse_kria"
# BOARD_TESTS_OMNV_PATH=${BOARD_TESTS_PATH}/omnivisor
# BOARD_ISOLATION_EXP_PATH=${BOARD_TESTS_OMNV_PATH}/experiments/isolation_exp
# BOARD_ISOLATION_INMATES_PATH=${BOARD_ISOLATION_EXP_PATH}/inmates
# BOARD_BOOT_EXP_PATH=${BOARD_TESTS_OMNV_PATH}/experiments/boot_exp
# BOARD_TACLEBENCH_PATH=${BOARD_TESTS_OMNV_PATH}/experiments/taclebench_exp
# BOARD_UTILITY_PATH=${BOARD_TESTS_OMNV_PATH}/utility

# # Create group on core0 to execute the tests
# echo "Create group on core0 to execute the tests"
# mkdir /sys/fs/cgroup/cpuset/test
# echo 0 > /sys/fs/cgroup/cpuset/test/cpuset.cpus
# echo 0 > /sys/fs/cgroup/cpuset/test/cpuset.mems

# # Start Omnivisor
# echo "Starting Omnivisor"
# bash ${BOARD_UTILITY_PATH}/jailhouse_start.sh

# # Apply Temporal Isolation
# echo "Starting bandwidth regulation"
# bash ${BOARD_UTILITY_PATH}/apply_temp_reg.sh -R ${RPU_BANDWIDTH} -F ${FPGA_BANDWIDTH} -A ${APU_BANDWIDTH} -r -f -a

#         # Apply DISTURB
#         # Preload in memory the RPU1 membomb
#         if [[ "${DISTURB}" -eq "1" ]]; then
            
#             timeout -s 9 ${TIMEOUT_MINUTES}m ssh root@${IP} "cp ${BOARD_ISOLATION_INMATES_PATH}/RPU1/RPU1-${core}-membomb-demo.elf /lib/firmware"
#             if [[ $ret_code -ne 0 ]]; then
#                 echo "ERROR, reboot"
#                 bash ${UTILITY_DIR}/board_restart.sh
#                 sleep 1m
#                 continue
#             fi
#             timeout -s 9 ${TIMEOUT_MINUTES}m ssh root@${IP} "cat /lib/firmware/RPU1-${core}-membomb-demo.elf > /dev/null"
#             if [[ $ret_code -ne 0 ]]; then
#                 echo "ERROR, reboot"
#                 bash ${UTILITY_DIR}/board_restart.sh
#                 sleep 1m
#                 continue
#             fi

#             # Start RPU1 membomb
#             echo "Starting RPU1 membomb"
#             timeout -s 9 ${TIMEOUT_MINUTES}m ssh root@${IP} "cd /lib/firmware;
#                             echo stop > /sys/class/remoteproc/remoteproc1/state;
#                             echo RPU1-${core}-membomb-demo.elf > /sys/class/remoteproc/remoteproc1/firmware;
#                             echo start > /sys/class/remoteproc/remoteproc1/state"
#             if [[ $ret_code -ne 0 ]]; then
#                 echo "ERROR, reboot"
#                 bash ${UTILITY_DIR}/board_restart.sh
#                 sleep 1m
#                 continue
#             fi
            

#             # Start APU membomb
#             echo "Starting APU membomb"
#             timeout -s 9 ${TIMEOUT_MINUTES}m ssh root@${IP} "${BOARD_ISOLATION_EXP_PATH}/bandwidth -l1 -c1 -p 0 -d 0 -b \"-a write -m 4096 -i12\" &
#                             ${BOARD_ISOLATION_EXP_PATH}/bandwidth -l1 -c2 -p 0 -d 0 -b \"-a write -m 4096 -i12\" &
#                             ${BOARD_ISOLATION_EXP_PATH}/bandwidth -l1 -c3 -p 0 -d 0 -b \"-a write -m 4096 -i12\" &"
#             if [[ $ret_code -ne 0 ]]; then
#                 echo "ERROR, reboot"
#                 bash ${UTILITY_DIR}/board_restart.sh
#                 sleep 1m
#                 continue
#             fi
            
#             # Start FPGA membomb
#             echo "Starting FPGA membomb"
#             if [[ $core == "RPU" ]]; then
                
#                 timeout -s 9 ${TIMEOUT_MINUTES}m ssh root@${IP} "devmem ${TRAFFIC_GENERATOR_1} 64 1"
#                 if [[ $ret_code -ne 0 ]]; then
#                     echo "ERROR, reboot"
#                     bash ${UTILITY_DIR}/board_restart.sh
#                     sleep 1m
#                     continue
#                 fi
#             elif [[ $core == "RISCV" ]]; then
#                 timeout -s 9 ${TIMEOUT_MINUTES}m ssh root@${IP} "devmem ${TRAFFIC_GENERATOR_2} 64 1"
#                 if [[ $ret_code -ne 0 ]]; then
#                     echo "ERROR, reboot"
#                     bash ${UTILITY_DIR}/board_restart.sh
#                     sleep 1m
#                     continue
#                 fi
                
#             fi 
#             timeout -s 9 ${TIMEOUT_MINUTES}m ssh root@${IP} "devmem ${TRAFFIC_GENERATOR_3} 64 1"
#             if [[ $ret_code -ne 0 ]]; then
#                 echo "ERROR, reboot"
#                 bash ${UTILITY_DIR}/board_restart.sh
#                 sleep 1m
#                 continue
#             fi
            

#             ## START TEST
#             echo "Starting Taclebench Test on ${core}"


#             # Remove kernel prints
#             timeout -s 9 ${TIMEOUT_MINUTES}m ssh root@${IP} "echo 1 > /proc/sys/kernel/printk"
#             if [[ $ret_code -ne 0 ]]; then
#                 echo "ERROR, reboot"
#                 bash ${UTILITY_DIR}/board_restart.sh
#                 sleep 1m
#                 continue
#             fi
            
#         fi