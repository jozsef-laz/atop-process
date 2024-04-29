```
time ./run-ir-test.sh --clusters=irp871-c76,irp871-c77 -x
time /ir_test/tools/bld_linux/bin/fsstress --config /ir_test/tools/bld_linux/fill_sim.cfg --duration 90 --server 10.88.210.197 --timeout 180 --path /hedgehog/left,/hedgehog/right --nfsdtype SIMULATION
purefs snap --send --target irp871-c77 hedgehog
```

checking on target whether the snapshot arrived
```
while true; do date; purefs list --snap --transfer; sleep 1; done
```

in cmux:
```
cmux -na
rm -f alma.raw; atop -w alma.raw 5
```

collecting logs:
```
time collect.sh -c irp871-c76 -l atop_blades
```

signal 31 is SIGUSR2
```
# from cluster:
exec.py -na 'pkill -u ir atop --signal 31'
# `-u ir` is needed, because there is another atop process running started by root
```