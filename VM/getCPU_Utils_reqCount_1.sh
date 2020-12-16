#!/bin/bash

var_DT=$1
cpu_tot=$(tail -500 "$(date +%Y%m%d)_res_util_smoothed" | awk -v CDT=$var_DT 'BEGIN{sum_cpu=0;counter=0}{if($3>=CDT){sum_cpu+=$1;counter+=1}}END{print sum_cpu,counter}')
echo "$cpu_tot"
