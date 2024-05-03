#! /bin/bash
retval_check () {
   RETVAL=$1
   if [ $RETVAL != 0 ]; then
      exit $RETVAL
   fi
}

SSHARGS=" \
   -o UserKnownHostsFile=/dev/null \
   -o StrictHostKeyChecking=no \
   -o LogLevel=ERROR \
"

DATAVIP=$(sshpass -p welcome ssh $SSHARGS irp871-c76 "purenetwork list" | grep ^data)
if [ -z "$DATAVIP" ]; then
    echo "Error: there's no data vip on the cluster"
    exit 1
fi
NUM_OF_TESTRUNS=3
date
echo "---> deleting alma.raw files on cluster <---"
sshpass -p welcome ssh $SSHARGS ir@irp871-c76 "exec.py -na \"rm -rf /home/ir/alma.raw\""
for i in $(seq $NUM_OF_TESTRUNS); do
    echo "---> starting testrun [$i] <---"
    echo "---> recreating hedgehog fs <---"
    time /home/ir/work/first/run-ir-test.sh --clusters=irp871-c76,irp871-c77 -x
    retval_check $?
    echo "---> running fsstress <---"
    time sshpass -p welcome ssh $SSHARGS ir@irp871-c76h01 "/ir_test/tools/bld_linux/bin/fsstress \
        --config /ir_test/tools/bld_linux/fill_sim.cfg \
        --duration 300 \
        --server 10.88.210.197 \
        --timeout 450 \
        --path /hedgehog/left,/hedgehog/right \
        --nfsdtype SIMULATION"
    retval_check $?
    echo "---> starting atop <---"
    sshpass -p welcome ssh $SSHARGS ir@irp871-c76 "exec.py -na \"atop -w /home/ir/alma.raw 5\"" &
    sleep 2
    echo "---> snap & send <---"
    sshpass -p welcome ssh $SSHARGS ir@irp871-c76 "purefs snap --send --target irp871-c77 hedgehog"
    retval_check $?
    echo "---> entering in-progress loop <---"
    IN_PROGRESS=""
    while [ -z "$IN_PROGRESS" ]; do
        date
        TRANSFER_LINE=$(sshpass -p welcome ssh $SSHARGS ir@irp871-c76 "purefs list --snap --transfer | tail -n 1")
        echo "$TRANSFER_LINE"
        IN_PROGRESS=$(echo "$TRANSFER_LINE" | grep "in-progress")
        sleep 1
    done
    echo "---> left in-progress loop <---"
    echo "---> entering completed loop <---"
    COMPLETED=""
    while [ -z "$COMPLETED" ]; do
        date
        TRANSFER_LINE=$(sshpass -p welcome ssh $SSHARGS ir@irp871-c76 "purefs list --snap --transfer | tail -n 1")
        echo "$TRANSFER_LINE"
        COMPLETED=$(echo "$TRANSFER_LINE" | grep "completed")
        sleep 1
    done
    echo "---> left completed loop <---"

    echo "---> killing atop <---"
    sshpass -p welcome ssh $SSHARGS ir@irp871-c76 "exec.py -na 'pkill -u ir atop --signal 31'"
    sleep 7
done
echo "---> collecting logs <---"
time collect.sh -c irp871-c76 -l atop_blades
date