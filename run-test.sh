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
CLUSTERS=(irp137-c21 irp204-c02)
printf -v CLUSTERS_JOINED_EXTRA_COMMA '%s,' "${CLUSTERS[@]}"
CLUSTERS_JOINED="${CLUSTERS_JOINED_EXTRA_COMMA%,}"
RUN_IR_TEST_CMD=/home/ir/work/misc/run-ir-test.sh

DATAVIP=$(sshpass -p welcome ssh $SSHARGS ${CLUSTERS[0]} "purenetwork list --csv" | grep ^data | cut -d',' -f4)
echo "---> DATAVIP=[$DATAVIP] <---"
if [ -z "$DATAVIP" ]; then
    echo "Error: there's no data vip on the cluster"
    exit 1
fi
NUM_OF_TESTRUNS=3
date
echo "---> deleting alma.raw files on cluster <---"
sshpass -p welcome ssh $SSHARGS ir@${CLUSTERS[0]} "exec.py -na \"rm -rf /home/ir/alma.raw\""
for i in $(seq $NUM_OF_TESTRUNS); do
    echo "---> starting testrun [$i] <---"
    echo "---> recreating hedgehog fs <---"
    time $RUN_IR_TEST_CMD --clusters=$CLUSTERS_JOINED -x
    retval_check $?
    echo "---> running fsstress <---"
    FSSTRESS_LOG_PATH="/home/ir/fsstress-$(date '+%H-%M-%S').log"
    echo "FSSTRESS_LOG_PATH=[$FSSTRESS_LOG_PATH]"
    time sshpass -p welcome ssh $SSHARGS ir@${CLUSTERS[0]}h01 "/ir_test/tools/bld_linux/bin/fsstress \
        --config /ir_test/tools/bld_linux/fill.cfg \
        --duration 300 \
        --server $DATAVIP \
        --timeout 450 \
        --path /hedgehog/left,/hedgehog/right \
        --nfsdtype SIMULATION >> $FSSTRESS_LOG_PATH"
    retval_check $?
    echo "---> starting atop <---"
    sshpass -p welcome ssh $SSHARGS ir@${CLUSTERS[0]} "exec.py -na \"atop -w /home/ir/alma.raw 5\"" &
    sleep 2
    echo "---> snap & send <---"
    sshpass -p welcome ssh $SSHARGS ir@${CLUSTERS[0]} "purefs snap --send --target ${CLUSTERS[1]} hedgehog"
    retval_check $?
    echo "---> entering in-progress loop <---"
    IN_PROGRESS=""
    while [ -z "$IN_PROGRESS" ]; do
        date
        TRANSFER_LINE=$(sshpass -p welcome ssh $SSHARGS ir@${CLUSTERS[0]} "purefs list --snap --transfer | tail -n 1")
        echo "$TRANSFER_LINE"
        IN_PROGRESS=$(echo "$TRANSFER_LINE" | grep "in-progress")
        sleep 1
    done
    echo "---> left in-progress loop <---"
    echo "---> entering completed loop <---"
    COMPLETED=""
    while [ -z "$COMPLETED" ]; do
        date
        TRANSFER_LINE=$(sshpass -p welcome ssh $SSHARGS ir@${CLUSTERS[0]} "purefs list --snap --transfer | tail -n 1")
        echo "$TRANSFER_LINE"
        COMPLETED=$(echo "$TRANSFER_LINE" | grep "completed")
        sleep 1
    done
    echo "---> left completed loop <---"

    echo "---> killing atop <---"
    sshpass -p welcome ssh $SSHARGS ir@${CLUSTERS[0]} "exec.py -na 'pkill -u ir atop --signal 31'"
    sleep 7
done
echo "---> collecting logs <---"
time collect.sh -c ${CLUSTERS[0]} -l atop_blades
date