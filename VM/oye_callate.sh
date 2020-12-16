#!/bin/bash

nc -l 37377

var_Proc_Stats=3

#cycleCount = 0
#while [[ $var_Proc_Stats -gt 0 ]]
#do
#   var_Proc_Stats=$(/bin/ps -efa | /bin/grep gst-launch-1.0 | /bin/grep -v "grep"  | /usr/bin/wc -l | /usr/bin/awk '{print $1}')
#   sleep 3
#   (( cycleCount += 1 ))
#   if [ $cycleCount -gt 10 ];
#   then
#       break       
#   fi
#done

sleep 30

sudo shutdown -f now
