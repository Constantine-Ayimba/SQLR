#!/bin/bash
(( RearView=$1*1000 ))
var_DT=$(date +%s%3N)
cpu_tot=$(tail -500 "$(date +%Y%m%d)_res_util" | awk -v LBW=$RearView -v CDT=$var_DT 'BEGIN{sum_cpu=0;counter=0}{if((CDT-$3)<=LBW){sum_cpu+=$1;counter+=1}}END{print sum_cpu,counter}')
echo "$cpu_tot"

