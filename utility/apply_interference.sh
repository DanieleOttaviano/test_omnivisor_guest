#!/bin/bash

# REGISTERS traffic generators
tg1=0x80000000
tg2=0x80010000
tg3=0x80020000

# DIRECTORIES
RPROC_SCRIPT_PATH="/root/scripts_remoteproc"
ISOL_EXP_PATH="/root/tests/test_omnivisor_guest/isolation_exp"

usage() {
  echo -e "Usage: $0 \r\n \
  Apply Interference from the following master:\r\n \
      [-a APU membomb]\r\n \
      [-r RPU1 membomb]\r\n \
      [-f FPGA traffic generator]" 1>&2
    exit 1
}

while getopts "arf" o; do
    case "${o}" in
    a)
        ${BOARD_ISOLATION_EXP_PATH}/bandwidth -l1 -c1 -p 0 -d 0 -b "-a write -m 4096 -i12" &
        ${BOARD_ISOLATION_EXP_PATH}/bandwidth -l1 -c2 -p 0 -d 0 -b "-a write -m 4096 -i12" &
        ${BOARD_ISOLATION_EXP_PATH}/bandwidth -l1 -c3 -p 0 -d 0 -b "-a write -m 4096 -i12" &
        ;;
    r)
        bash ${RPROC_SCRIPT_PATH}/remoteproc1_stop.sh
        bash ${RPROC_SCRIPT_PATH}/remoteproc1_launch.sh
        ;;
    f)
        devmem ${tg1} 64 1
        devmem ${tg2} 64 1
        devmem ${tg3} 64 1
        ;;
    *)
        usage
        ;;
    esac
done
