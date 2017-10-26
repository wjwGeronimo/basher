#!/usr/bin/env bash

barprint(){
	#tput el
	echo -n "["
	for i in `seq $MARK`
	do
		echo -n "#"
	done
	if [[ $I -eq 0 ]]
	then
		echo -n "-"
	elif [[ $I -eq $TOTAL ]]
	then
		echo -n "#"
	else
		echo -n "+"
	fi
	for i in `seq $NULL`
	do
		echo -n "-"
	done
	echo "] $PROG $DAT"
	#tput cuu1
}

onetime(){
	I=$1
	TOTAL=$2

	COLS=$(tput cols)

	DAT=$(date +%T)
	[[ $COLS -le 30 ]]&&DAT=""
	DC=${#DAT}

	PROG="${I}/${TOTAL}"
	[[ $COLS -le 10 ]]&&PROG=""
	PC=${#PROG}

	WP=$((COLS-DC-PC-4))
	[[ $I -eq $TOTAL ]]&&MARK=$(((I*WP/TOTAL)-1))||MARK=$((I*WP/TOTAL))
	NULL=$((WP-MARK-1))

	barprint
}

cycle(){
	I=$1
	TOTAL=$2
	TIMER=$3

	echo
	while [[ $I -le $TOTAL ]]
	do
		tput cuu1
		onetime $I $TOTAL
		((I++))
		sleep $TIMER
	done
}
