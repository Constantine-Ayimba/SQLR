#!/bin/bash 
cd ~cayimba
nohup ./StatsSender2.sh 37073 &
nohup ./StatsSender1.sh 43000 &
nohup ./StatsSender3.sh 47000 &
nohup ./StatsSender4.sh 37021 &
