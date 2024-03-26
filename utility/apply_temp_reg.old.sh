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

while getopts "rfa" o; do
  case "${o}" in
  r)
    # w = 4                 is the size in bytes of a transaction
    # Ql = ar_r = aw_r = 10 is the level or regulation
    # fclk = 0.5 GHz        is the frequency of the DDR clock
    # bw = (w * Ql * fclk) / 2^32 = (4 * 10 * 0.5 * 10^9)/2^32 = 4,7 Mb/s
    jailhouse qos rpu1:ar_b=1,aw_b=1,ar_r=10,aw_r=10              # RPU-1 on ZCU102
    ;;
  f)
    # w = 4                 is the size in bytes of a transaction
    # Ql = ar_r = aw_r = 10 is the level or regulation
    # fclk = 0.5 GHz        is the frequency of the DDR clock
    # bw = (w * Ql * fclk) / 2^32 = (4 * 10 * 0.5 * 10^9)/2^32 = 4,7 Mb/s
    # jailhouse qos intfpdsmmutbu3:ar_b=1,aw_b=1,ar_r=10,aw_r=10  # RISC-V on FPGA should not be regulated in the tests
    jailhouse qos intfpdsmmutbu4:ar_b=1,aw_b=1,ar_r=10,aw_r=10    # Traffic Generator 1 and 2 on FPGA
    jailhouse qos intfpdsmmutbu5:ar_b=1,aw_b=1,ar_r=10,aw_r=10    # Traffic Generator 3 on FPGA
    ;;
  a)
    # every 1000 us limit the bandwidth to 78 writes (1 write = 64 bytes)
    # bw = 78 * 64 / 1000 = 4.992 MB/s
    jailhouse memguard 1 1000 78 w
    jailhouse memguard 2 1000 78 w
    jailhouse memguard 3 1000 78 w
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