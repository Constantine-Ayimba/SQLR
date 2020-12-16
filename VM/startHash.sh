#!/bin/bash
nohup /home/cayimba/procMon.sh > procMon.log 2&>1 &
/home/cayimba/runStatSender.sh & # > instanceMon.log 2&>1 &
nohup /home/cayimba/callate.sh  37377 >> /home/cayimba/callate.log 2&>1 &
/home/cayimba/start_Hash.sh 1500 10
