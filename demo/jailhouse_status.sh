#!/bin/bash
source "$(dirname "$0")/../utility/default_directories.sh"

usage() {
	echo -e "\
Usage: $0 [-e] [-d] [-h]
This script change Jailhouse status:
    [-e Enable Jailhouse]
    [-d Disable Jailhouse]
    [-h help]" 1>&2
    exit 1
}

ENABLE=0
DISABLE=0

while getopts "edh" o; do
    case "${o}" in
        e)
			ENABLE=1
            ;;
        d)
			DISABLE=1
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
if [[ "${ENABLE}" == "${DISABLE}" ]]; then
	echo "One option among [-e] and [-d] has to be provided"
	usage
	exit 1
fi

if [[ "${ENABLE}" == 1 ]]; then
	# Start Omnivisor
    echo "Starting Omnivisor"
    bash ${UTILITY_DIR}/jailhouse_start.sh
fi

if [[ "${DISABLE}" == 1 ]]; then
    # Disable Omnivisor
    echo "Stopping Omnivisor"
    ${JAILHOUSE_PATH}/tools/jailhouse disable
fi