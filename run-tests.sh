#! /bin/bash
/home/ir/work/first/throttle 5
/home/ir/work/first/encryption off
sleep 60
time ./run-test.sh
/home/ir/work/first/encryption on
sleep 60
time ./run-test.sh