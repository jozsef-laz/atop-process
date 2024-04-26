import sys
import datetime

class Sample:
    def __init__(self, timestamp: str, systick: str, usertick: str):
        self.dt = datetime.datetime.fromtimestamp(int(timestamp))
        self.systick = int(systick)
        self.usertick = int(usertick)

samples: list[Sample] = []
firstSkipped = False
for line in sys.stdin:
    if line.startswith('SEP') or line.startswith('RESET'):
        continue
    if not firstSkipped:
        # skip the first
        firstSkipped = True
        continue
    if line.startswith('CPU'):
        # example:
        #CPU ch1-fb1 1714061219 2024/04/25 18:06:59 5 100 10 434 731 476 3142 4 0 85 1 0 21940 100 0 0
        one_line_data = line.split()
        one_sample = Sample(one_line_data[2], one_line_data[8], one_line_data[9])
        samples.append(one_sample)

for s in samples:
    print(f'{s.dt}, {s.systick}, {s.usertick}')