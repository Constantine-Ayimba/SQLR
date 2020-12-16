#!/bin/bash

cd ~cayimba
Prev_cpu=0
Prev_mem=0
Beta=0.5
RearView=2000 #milliseconds of back average
while [[ 1 ]]
do
        var_proc=$(cat <(/bin/grep 'cpu ' /proc/stat) <(sleep 1 && grep 'cpu ' /proc/stat) | awk -v RS= '{print ($13-$2+$15-$4)*100/($13-$2+$15-$4+$16-$5)}');
        var_mem=$(free -m | /bin/grep 'Mem:' | awk -v RS= '{print $3}');
	var_DT=$(date +%s%3N)
	var_FT=$(/bin/date +%Y%m%d)
        echo $var_proc" "$var_mem" "$var_DT >> "$(date +%Y%m%d)_res_util"
        echo "$(echo $var_proc | awk '{print $1/100}') $var_mem $var_DT" >> $var_FT"_res_util_smoothed"
        #tail -10 "$(date +%Y%m%d)_res_util" | awk -v LBW=$RearView -v CDT=$var_DT 'BEGIN{counter=0;sum_cpu=0;sum_mem=0}{if($3!=""){if((CDT-$3)<=LBW){sum_cpu+=$1;sum_mem+=$2;counter+=1}}}END{if(counter>0){print (sum_cpu/counter),(sum_mem/counter),CDT}}' >> $var_FT"_res_util_smoothed"
        #tail -1 "$(date +%Y%m%d)_res_util" | awk -v CDT=$var_DT '{print $1,$2,CDT}' >> $var_FT"_res_util_smoothed"
        #Prev_cpu=$(tail -1 $var_FT"_res_util_smoothed" | awk '{print $1}')
        #Prev_mem=$(tail -1 $var_FT"_res_util_smoothed" | awk '{print $2}')
        #sleep 0.001
done

