#!/bin/bash
while :; do
	x="$(ls -l --time-style=full-iso z80os.asm | cut -d ' ' -f 7)"
	if [ "$x" != "$y" ]; then
		busybox reset
		y="$x"
		z="$(z80asm z80os.asm 2>&1)"
		echo "$z"
		if [ "$z" == "" ]; then hexdump -v -C a.bin; fi
		date
		echo $(echo $(ls -l a.bin | cut -d ' ' -f 5) - 3 | bc) bytes
		echo
	fi
	sleep 1
done
