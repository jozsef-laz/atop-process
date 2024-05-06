This repo is a collection of scripts I made for collecting and measuring CPU usage of encrypted File Replication.

Files for measuring the testcases with atop:
 * `run-tests.sh`: runs testcases with different settings
 * `run-test.sh`: runs one testcase multiple times, starts/stops atop, collects logs

Files for processing atop measurments:
 * `process.py`: processes atop's table output
 * `run`: just a convinience script, feeds `process.py` with atop raw measurment
 * `create-result-csv.sh`: runs `run` script for multiple measurements

Other stuff:
 * `plot.gpi`: gnuplot script to create plot
 * `commands.md`: some useful commands I used during the experiments

Other files, which are used, but are not in this repo:
 * `run-ir-test.sh`, `collect.sh`: can be found here: https://github.com/jozsef-laz/pure-misc