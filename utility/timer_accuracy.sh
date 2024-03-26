#!/bin/bash

hex_to_dec() {
	echo "$1" | xargs printf "%d\n"
}

start_hex=$(devmem 0xFF250000)
sleep 1
end_hex=$(devmem 0xFF250000)

start_dec=$(hex_to_dec $start_hex)
end_dec=$(hex_to_dec $end_hex)
difference=$((end_dec - start_dec))

echo "Start (hex): $start_hex, Start (dec): $start_dec"
echo "End (hex): $end_hex, End (dec): $end_dec"
echo "Difference: $difference"

echo The timer count $difference in 1 Second
