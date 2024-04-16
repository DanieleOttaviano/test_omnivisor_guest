#!/bin/bash

source /etc/profile
echo $$ >> /sys/fs/cgroup/cpuset/test/cgroup.procs

usage() {
  echo -e "Usage: $0 \r\n \
  Apply bandwidth regulation using Jailhouse interface:\r\n \
      [-r RPU-1 regulation using QoS]\r\n \
      [-f FPGA regulation using QoS]\r\n \
      [-a APU regulation using Memguard]" 1>&2
    exit 1
}

dut_qos_value=10 # default value, 4.7MB/s
r_qos_value=10 # default value, 4.7MB/s
f_qos_value=10 # default value, 4.7MB/s
a_memguard_value=78 # default value, 4.992 MB/s

while getopts "R:F:A:rfaD:dB:" o; do
  case "${o}" in
  R)
    # r_qos_value=`echo ${OPTARG} | python3 -c "print(int(pow(2, 32) / pow(10,9) * float(input()) / (4 * .5)))"`
    r_qos_value=`echo "\`echo "2^31 / 10^9 * ${OPTARG}" | bc -l\` / 1" | bc`
    echo "RPU 1 QOS VALUE: ${r_qos_value}"
    ;;
  F)
    f_qos_value=`echo "\`echo "2^31 / 10^9 * ${OPTARG}" | bc -l\` / 1" | bc`
    echo "FPGA QOS VALUE: ${f_qos_value}"
    ;;
  A)
    a_memguard_value=`echo "\`echo "${OPTARG} * 1000 / 64" | bc -l\` / 1" | bc`
    echo "APU MEMGUARD W VALUE: ${a_memguard_value}"
    ;;
  r)
    # w = 4                 is the size in bytes of a transaction
    # Ql = ar_r = aw_r = 10 is the level or regulation
    # fclk = 0.5 GHz        is the frequency of the DDR clock
    # bw = (w * Ql * fclk) / 2^32 = (4 * 10 * 0.5 * 10^9)/2^32 = 4,7 Mb/s
    jailhouse qos rpu1:ar_b=1,aw_b=1,ar_r=${r_qos_value},aw_r=${r_qos_value}              # RPU-1 on ZCU102
    ;;
  f)
    # w = 4                 is the size in bytes of a transaction
    # Ql = ar_r = aw_r = 10 is the level or regulation
    # fclk = 0.5 GHz        is the frequency of the DDR clock
    # bw = (w * Ql * fclk) / 2^32 = (4 * 10 * 0.5 * 10^9)/2^32 = 4,7 Mb/s
    # jailhouse qos intfpdsmmutbu3:ar_b=1,aw_b=1,ar_r=10,aw_r=10  # RISC-V on FPGA should not be regulated in the tests
    jailhouse qos intfpdsmmutbu4:ar_b=1,aw_b=1,ar_r=${f_qos_value},aw_r=${f_qos_value}    # Traffic Generator 1 and 2 on FPGA
    jailhouse qos intfpdsmmutbu5:ar_b=1,aw_b=1,ar_r=${f_qos_value},aw_r=${f_qos_value}    # Traffic Generator 3 on FPGA
    ;;
  a)
    # every 1000 us limit the bandwidth to 78 writes (1 write = 64 bytes)
    # bw = 78 * 64 / 1000 = 4.992 MB/s
    jailhouse memguard 1 1000 ${a_memguard_value} w
    jailhouse memguard 2 1000 ${a_memguard_value} w
    jailhouse memguard 3 1000 ${a_memguard_value} w
    ;;
  D)
    dut_qos_value=`echo ${OPTARG} | python3 -c "print(int(pow(2, 32) / pow(10,9) * float(input()) / (4 * .5)))"`
    ;;
  d)
    jailhouse qos intfpdsmmutbu3:ar_b=1,aw_b=1,ar_r=${dut_qos_value},aw_r=${dut_qos_value}  # RISC-V on FPGA
    jailhouse qos rpu0:ar_b=1,aw_b=1,ar_r=${dut_qos_value},aw_r=${dut_qos_value}            # RPU-0 on ZCU102
    ;;
  B)
    r_qos_value=`echo "\`echo "2^31 / 10^9 * ${OPTARG}" | bc -l\` / 1" | bc`
    echo "RPU 1 QOS VALUE: ${r_qos_value}"
    f_qos_value=`echo "\`echo "2^31 / 10^9 * ${OPTARG}" | bc -l\` / 1" | bc`
    echo "FPGA QOS VALUE: ${f_qos_value}"
    a_memguard_value=`echo "\`echo "${OPTARG} * 1000 / 64" | bc -l\` / 1" | bc`
    echo "APU MEMGUARD W VALUE: ${a_memguard_value}"
    ;;
  *)
    usage
    ;;
  esac
done

    # # Peripherials in LPD with QoS Support 
    # jailhouse qos rpu0:ar_b=1,aw_b=1,ar_r=1,aw_r=1
    # jailhouse qos rpu1:ar_b=1,aw_b=1,ar_r=1,aw_r=1
    # jailhouse qos adma:ar_b=1,aw_b=1,ar_r=1,aw_r=1
    # jailhouse qos afifm6:ar_b=1,aw_b=1,ar_r=1,aw_r=1
    # jailhouse qos dap:ar_b=1,aw_b=1,ar_r=1,aw_r=1
    # jailhouse qos usb0:ar_b=1,aw_b=1,ar_r=1,aw_r=1
    # jailhouse qos usb1:ar_b=1,aw_b=1,ar_r=1,aw_r=1
    # jailhouse qos intiou:ar_b=1,aw_b=1,ar_r=1,aw_r=1
    # jailhouse qos intcsupmu:ar_b=1,aw_b=1,ar_r=1,aw_r=1
    # jailhouse qos intlpdinbound:ar_b=1,aw_b=1,ar_r=1,aw_r=1
    # jailhouse qos intlpdocm:ar_b=1,aw_b=1,ar_r=1,aw_r=1
    # jailhouse qos ib5:ar_b=1,aw_b=1,ar_r=1,aw_r=1
    # jailhouse qos ib6:ar_b=1,aw_b=1,ar_r=1,aw_r=1
    # jailhouse qos ib8:ar_b=1,aw_b=1,ar_r=1,aw_r=1
    # jailhouse qos ib0:ar_b=1,aw_b=1,ar_r=1,aw_r=1
    # jailhouse qos ib11:ar_b=1,aw_b=1,ar_r=1,aw_r=1
    # jailhouse qos ib12:ar_b=1,aw_b=1,ar_r=1,aw_r=1

    # # Peripherials in FPD with QoS Support
    # jailhouse qos intfpdcci:ar_b=1,aw_b=1,ar_r=1,aw_r=1
    # jailhouse qos intfpdsmmutbu3:ar_b=1,aw_b=1,ar_r=1,aw_r=1
    # jailhouse qos intfpdsmmutbu4:ar_b=1,aw_b=1,ar_r=1,aw_r=1
    # jailhouse qos afifm0:ar_b=1,aw_b=1,ar_r=1,aw_r=1
    # jailhouse qos afifm1:ar_b=1,aw_b=1,ar_r=1,aw_r=1
    # jailhouse qos afifm2:ar_b=1,aw_b=1,ar_r=1,aw_r=1
    # jailhouse qos intfpdsmmutbu5:ar_b=1,aw_b=1,ar_r=1,aw_r=1 
    # jailhouse qos dp:ar_b=1,aw_b=1,ar_r=1,aw_r=1
    # jailhouse qos afifm3:ar_b=1,aw_b=1,ar_r=1,aw_r=1
    # jailhouse qos afifm4:ar_b=1,aw_b=1,ar_r=1,aw_r=1
    # jailhouse qos afifm5:ar_b=1,aw_b=1,ar_r=1,aw_r=1
    # jailhouse qos gpu:ar_b=1,aw_b=1,ar_r=1,aw_r=1
    # jailhouse qos pcie:ar_b=1,aw_b=1,ar_r=1,aw_r=1
    # jailhouse qos gdma:ar_b=1,aw_b=1,ar_r=1,aw_r=1
    # jailhouse qos sata:ar_b=1,aw_b=1,ar_r=1,aw_r=1
    # jailhouse qos coresight:ar_b=1,aw_b=1,ar_r=1,aw_r=1
    # jailhouse qos issib2:ar_b=1,aw_b=1,ar_r=1,aw_r=1
    # jailhouse qos issib6:ar_b=1,aw_b=1,ar_r=1,aw_r=1