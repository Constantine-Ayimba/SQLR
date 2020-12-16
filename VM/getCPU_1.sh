#!/bin/bash
#uptime | awk '{iAvg=index($0,"average");print substr($0,iAvg+1+length("average:"),4)}'
tail -1 "$(/bin/date +%Y%m%d)_res_util_smoothed" | awk '{print $1}'
#tail -30 "$(/bin/date +%Y%m%d)_res_util_smoothed" | awk -v cutOffTime=$(( $(date +'%s%3N')-(10*1000) )) 'BEGIN{sumIn=0;counta=0}{if($3>=cutOffTime){sumIn+=$1;counta++}}END{if(counta>0){print (sumIn/counta)}else{print 0}}'
