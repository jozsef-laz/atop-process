import sys

class Sample:
    def __init__(self, systick: str, usertick: str):
        self.systick = int(systick)
        self.usertick = int(usertick)
    def __str__(self):
        return f"<sys={self.systick}, user={self.usertick}>"

# dict: timestamp -> list of samples (from each blade exactly 1)
samples: dict[int, list[Sample]] = {}
# the first batch of data of each log is some non-sense data,
# so let's just skip it, and iterate until next SEP line
continueTillNextSEP = False
for line in sys.stdin:
    if line.startswith('SEP'):
        if continueTillNextSEP:
            continueTillNextSEP = False
        continue
    if line.startswith('RESET'):
        # next blade's log is coming
        continueTillNextSEP = True
        continue
    if continueTillNextSEP:
        continue
    if line.startswith('CPU'):
        # example:
        #CPU ch1-fb1 1714061219 2024/04/25 18:06:59 5 100 10 434 731 476 3142 4 0 85 1 0 21940 100 0 0
        one_line_data = line.split()
        one_sample = Sample(one_line_data[8], one_line_data[9])
        timestamp = int(one_line_data[2])
        if timestamp in samples:
            samples[timestamp].append(one_sample)
        else:
            samples[timestamp] = [one_sample]

# creating average numbers
startTimestamp = min(samples.keys())
averages: dict[int, Sample] = {}
numOfBlades=len(next(iter(samples.values())))
for timestamp, sampleList in samples.items():
    #print(f'{timestamp}, list: {", ".join([str(sample) for sample in sampleList])}')
    assert len(sampleList) == numOfBlades, f"at timestamp {timestamp} we have different number of samples"
    systicks = [sample.systick for sample in sampleList]
    userticks = [sample.usertick for sample in sampleList]
    systick_average = round(float(sum(systicks)) / numOfBlades)
    usertick_average = round(float(sum(userticks)) / numOfBlades)
    relativeTimestamp = timestamp-startTimestamp
    averages[relativeTimestamp] = Sample(systick_average, usertick_average)

# write out average numbers to a csv
with open("result.csv", "w") as f:
    f.write(f'# timestamp, systick, usertick\n')
    for timestamp, sample in averages.items():
        f.write(f'{timestamp},{sample.systick},{sample.usertick}\n')