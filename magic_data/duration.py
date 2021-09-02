

f = open('data/train/utt2dur')
duration = 0
for line in f.readlines():
	time = line.split()
	duration += float(time[1])
print(duration)
