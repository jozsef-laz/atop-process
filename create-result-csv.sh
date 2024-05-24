#! /bin/bash
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
LOGDIRS=(
irp137-c21_2024-05-24-T13-39-59-no-thr-no-enc
irp137-c21_2024-05-24-T14-15-58-no-thr-ENC
irp137-c21_2024-05-24-T15-02-59-THR-no-enc
irp137-c21_2024-05-24-T15-47-28-THR-ENC
)
for LOGDIR in ${LOGDIRS[@]}; do
    cd $SCRIPT_DIR/$LOGDIR/irp137-c21
    echo "---> processing LOGDIR=[$LOGDIR] <---"

    # making result.csv
    SUFFIX=$(echo "$LOGDIR" | cut -c 32-)
    NEW_RESULT_NAME="result$SUFFIX.csv"
    echo "$NEW_RESULT_NAME"
    ../../run
    mv result.csv $NEW_RESULT_NAME
    cp $NEW_RESULT_NAME ~

    # making all-data.csv
    echo all-data$SUFFIX.csv
    atopcat ir*/alma.raw | atop -r - -P CPU | sed -e '/SEP/d' -e '/RESET/,+1d' | sed -e 's/ /,/g' > all-data.csv
    cp all-data.csv ~/all-data$SUFFIX.csv

    echo
done