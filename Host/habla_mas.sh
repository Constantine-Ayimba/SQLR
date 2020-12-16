#!/bin/bash

#/usr/bin/virsh list --all | grep "running" | awk '{print $2}' 
/usr/bin/virsh start $1
