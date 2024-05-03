#! /bin/bash
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
LOGDIRS=(
irp871-c76_2024-05-02-T18-04-38-no-thr-no-enc
irp871-c76_2024-05-02-T18-37-12-no-thr-ENC
irp871-c76_2024-05-02-T19-30-29-THR-no-enc
irp871-c76_2024-05-02-T20-21-19-THR-ENC
)
for LOGDIR in ${LOGDIRS[@]}; do
    cd $SCRIPT_DIR/$LOGDIR/irp871-c76

    # making result.csv
    ../../run
    SUFFIX=$(echo "$LOGDIR" | cut -c 32-)
    NEW_RESULT_NAME="result$SUFFIX.csv"
    mv result.csv $NEW_RESULT_NAME
    cp $NEW_RESULT_NAME ~
    echo "$NEW_RESULT_NAME"

    # making all-data.csv
    atopcat ir*/alma.raw | atop -r - -P CPU | sed -e '/SEP/d' -e '/RESET/,+1d' | sed -e 's/ /,/g' > all-data.csv
    cp all-data.csv ~/all-data$SUFFIX.csv
    echo all-data$SUFFIX.csv
done