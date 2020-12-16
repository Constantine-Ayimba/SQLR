#!/bin/bash

startDate=$(date +%Y%m%d)
stepTo=$1

N_o=$(awk -v ST=$stepTo '{if($1>=ST){print}}' $startDate"_rejected" | wc -l)
N_tot=$(awk -v ST=$stepTo '{if($1>=ST){print}}' $startDate"_petitio" | wc -l)
echo "$N_o $N_tot" | awk '{if($2>0){print ($1/$2)}else{print 0}}'
