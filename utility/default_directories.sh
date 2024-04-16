#!/bin/bash

# TEST DIRECTORIES
CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
TEST_OMNV_GUEST_DIR=$(dirname "${CURRENT_DIR}")
UTILITY_DIR=${TEST_OMNV_GUEST_DIR}/utility

OUTPUT_LOG="/dev/null" #"/tmp/boot_time.log"

# BOOT EXPERIMENTS
BOOT_EXP_PATH="/root/tests/test_omnivisor_guest/experiments/boot_exp"
BOOT_INMATES_PATH=${BOOT_EXP_PATH}/inmates
BOOT_RESULTS_PATH="/root/tests/test_omnivisor_guest/results/boot_results"
REMOTEPROC0_PATH="/sys/class/remoteproc/remoteproc0"

# ISOLATION EXPERIMENTS
ISOLATION_EXP_PATH="/root/tests/test_omnivisor_guest/experiments/isolation_exp"
ISOLATION_INMATES_PATH=${ISOLATION_EXP_PATH}/inmates/

# TACLEBENCH EXPERIMENTS
BENCH_DIR="/root/tests/test_omnivisor_guest/experiments/taclebench_exp/inmates"
TACLE_EXP_PATH="/root/tests/test_omnivisor_guest/experiments/taclebench_exp"
TACLEBENCH_RES_DIR="/root/tests/test_omnivisor_guest/results/taclebench_results/"
ARM64_CELL_PATH="/root/jailhouse/configs/arm64"

# Jailhouse directories
JAILHOUSE_PATH="/root/jailhouse"
JAIL_SCRIPT_PATH="/root/scripts_jailhouse_kria"