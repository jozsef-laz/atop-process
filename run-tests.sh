#! /bin/bash

throttle_cmd=/home/ir/work/second/throttle
encryption_cmd=/home/ir/work/second/encryption

# throttle off
$throttle_cmd off
$encryption_cmd off
sleep 60
time ./run-test.sh
$encryption_cmd on
sleep 60
time ./run-test.sh

# throttle
$throttle_cmd 1500
$encryption_cmd off
sleep 60
time ./run-test.sh
$encryption_cmd on
sleep 60
time ./run-test.sh