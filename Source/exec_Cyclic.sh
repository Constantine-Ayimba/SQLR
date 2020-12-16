#!/bin/bash
cd

var_ip="192.168.1.73" #IP of Host
var_portOff=$1
var_port=$2
var_FileOff=0

#declare limits=(16 8 6 5 4 3 2 3 4 5 6 8)
declare limits=(10 10 8 8 6 6 7 7 6 6 7 6 6 7 6 6 7 7 6 6 8 8 10 10)

counta=1
while [ 1 ]

do
	date_ref=$(date --date="$(date +'%Y-%m-%d')" +'%s%3N')
	curr_date=$(date +'%s%3N')
	
	(( var_sleepOff=($curr_date-$date_ref)/(60*60*1000) ))
	
	if [[ $var_sleepOff -gt 23 ]];
	then
		var_sleepOff=0 
	fi
	
	sleep_time=$RANDOM

	(( sleep_time%=${limits[$var_sleepOff]} ))

	port_Off=$RANDOM

	file_Off=$RANDOM
	(( file_selector=$var_FileOff+($file_Off%10) ))

	(( port_Waiter=0 )) #$counta%3 ))

	(( port_Off%=1000 ))
	(( G_porter=$var_port+$port_Off ))
	(( tcp_port=$port_Waiter+$var_portOff ))

	echo $(date +'%s%3N')" ReqID:"$file_selector" $var_ip":"$G_porter
	echo $tcp_port" : "$G_porter" : "$file_selector
	echo " sleep for "$sleep_time
	sleep  $sleep_time

	./T_start.sh $var_ip $tcp_port $G_porter $file_selector &
	(( counta+=1 ))
done
