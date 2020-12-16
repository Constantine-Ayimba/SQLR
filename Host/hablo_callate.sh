#!/bin/bash

echo "callate!" | nc $1 37377 &
