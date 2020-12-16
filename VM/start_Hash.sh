#!/bin/bash
cd ~cayimba

loop_count=0
while [ $loop_count -le $2 ]
do
	(( portVal=33000+$loop_count ))
	nohup ./NetBit.sh $1 $portVal >> "NetBit_$portVal.log" 2>&1 &
	(( loop_count+=1 ))
done
