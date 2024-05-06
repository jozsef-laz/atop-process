import sys
import math

class Sample:
    def __init__(self, systick: str, usertick: str):
        self.systick = int(systick)
        self.usertick = int(usertick)
        self.systick_std_dev = 0
        self.usertick_std_dev = 0

    def set_std_dev(self, systick_std_dev, usertick_std_dev):
        self.systick_std_dev = systick_std_dev
        self.usertick_std_dev = usertick_std_dev

    def __str__(self):
        return f"<sys={self.systick}, user={self.usertick}>"

def average(numbers: list[int]) -> float:
    return float(sum(numbers)) / len(numbers)

def std_dev(numbers: list[int]) -> float:
    sqrs = [n*n for n in numbers]
    a = average(numbers)
    sa = average(sqrs)
    return math.sqrt(sa - a*a)

# dict: time -> list of samples
#   - where time is the elapsed time from the start of each test
#   - each sample is an instance of `Sample`, containing values of a blade
# so with multiple test runs, each blade provides multiple samples for each time=0, 5, ...
samples: dict[int, list[Sample]] = {}
# the first batch of data of each log is some non-sense data,
# so let's just skip it, and iterate until next SEP line
continueTillNextSEP = False
startTimestamp = 0
for line in sys.stdin:
    if line.startswith('SEP'):
        if continueTillNextSEP:
            continueTillNextSEP = False
        continue
    if line.startswith('RESET'):
        # after each RESET, new data series starts
        startTimestamp = 0
        # next blade's log is coming
        continueTillNextSEP = True
        continue
    if continueTillNextSEP:
        continue

    # processing real data
    if startTimestamp == 0:
        one_line_data = line.split()
        startTimestamp = int(one_line_data[2])
    if line.startswith('CPU'):
        # example:
        #CPU ch1-fb1 1714061219 2024/04/25 18:06:59 5 100 10 434 731 476 3142 4 0 85 1 0 21940 100 0 0
        one_line_data = line.split()
        one_sample = Sample(one_line_data[8], one_line_data[9])
        relativeTime = int(one_line_data[2]) - startTimestamp
        if relativeTime in samples:
            samples[relativeTime].append(one_sample)
        else:
            samples[relativeTime] = [one_sample]

# creating average numbers
startTimestamp = min(samples.keys())
assert startTimestamp == 0
averages: dict[int, Sample] = {}
for timestamp, sampleList in samples.items():
    #l = ", ".join([str(s) for s in sampleList])
    #print(f"at timestamp {timestamp} we have [{len(sampleList)}] number of samples: {l}")
    systicks = [sample.systick for sample in sampleList]
    userticks = [sample.usertick for sample in sampleList]
    sample = Sample(average(systicks), average(userticks))

    sample.set_std_dev(std_dev(systicks), std_dev(userticks))

    averages[timestamp] = sample

# write out average numbers to a csv
with open("result.csv", "w") as f:
    f.write(f'# timestamp, systick, systick.std_dev, usertick, usertick.std_dev\n')
    for timestamp, sample in averages.items():
        f.write(f'{timestamp},{sample.systick},{sample.systick_std_dev},{sample.usertick},{sample.usertick_std_dev}\n')

# integrating the measurements to get the area below the graph (time - tics)
numOfSamples = 0 # number of samples we integrated together
# timePeriodOfSamples = 5 # [sec] each sample was collected over this time period
sysInt = 0
userInt = 0
for timestamp, sampleList in samples.items():
    for sample in sampleList:
        sysInt += sample.systick
        userInt += sample.usertick
        numOfSamples += 1

# for now we calculate the values for the whole timePeriodOfSamples, not for 1 sec
# averageSysTicksPerSec = float(sysInt) / numOfSamples / timePeriodOfSamples
# averageUserTicksPerSec = float(userInt) / numOfSamples / timePeriodOfSamples
averageSysTicks = float(sysInt) / numOfSamples
averageUserTicks = float(userInt) / numOfSamples
print(f'averageSysTicks={averageSysTicks}, averageUserTicks={averageUserTicks}')

allSysTicks = [sample.systick for _, sampleList in samples.items() for sample in sampleList]
allUserTicks = [sample.usertick for _, sampleList in samples.items() for sample in sampleList]
stdDevSys = std_dev(allSysTicks)
stdDevUser = std_dev(allUserTicks)
print(f'stdDevSys={stdDevSys}, stdDevUser={stdDevUser}')

# calculate integral again without outliers
# outliers: those values which are further from average than 2 sigma
numOfSamples = 0
sysInt = 0
userInt = 0
for timestamp, sampleList in samples.items():
    for sample in sampleList:
        if abs(sample.systick - averageSysTicks) > 2*stdDevSys:
            # print(f'removing systick: <{timestamp}, {sample.systick}>')
            continue
        sysInt += sample.systick
        numOfSamples += 1
averageSysTicks = float(sysInt) / numOfSamples

numOfSamples = 0
for timestamp, sampleList in samples.items():
    for sample in sampleList:
        if abs(sample.usertick - averageUserTicks) > 2*stdDevUser:
            # print(f'removing usertick: <{timestamp}, {sample.usertick}>')
            continue
        userInt += sample.usertick
        numOfSamples += 1
averageUserTicks = float(userInt) / numOfSamples

print(f'without outliers: averageSysTicks={averageSysTicks}, averageUserTicks={averageUserTicks}')
print(f'without outliers: averageSysPerc={averageSysTicks/5.0}, averageUserPerc={averageUserTicks/5.0}')