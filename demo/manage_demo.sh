#!/bin/bash

SETUP=0
DIR=$(dirname "$0")

while getopts "bh" o; do
    case "${o}" in
        b)
            SETUP=1
            ;;
        *)
            usage
            ;;
    esac
done

if [[ $SETUP == 1 ]]; then
    echo "Setup board for demo"

    bash $DIR/manage_jailhouse.sh -d
    bash $DIR/disturb_manager.sh -d APU -a Disable
    bash $DIR/disturb_manager.sh -d RPU1 -a Disable
    bash $DIR/disturb_manager.sh -d FPGA -a Disable
    
    bash $DIR/manage_jailhouse.sh -e
fi