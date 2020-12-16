#!/bin/bash

/usr/bin/virsh list --all | grep "running" | wc -l
