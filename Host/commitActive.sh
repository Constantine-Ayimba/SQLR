#!/bin/bash

if [ $1 == "0" ];
then
	cat /dev/null > ReadyVMS
else
	echo "$1" >> ReadyVMS
fi
