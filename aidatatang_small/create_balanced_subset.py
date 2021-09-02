import sys
import os
import math
from random import randint

directory = sys.argv[1]
spk_count = int(sys.argv[2])
speakers = set()
for dir in os.listdir(directory):
    for file in os.listdir(directory + '/' + dir):
        if file.endswith(".metadata"):
            f = open(directory + '/' + dir + '/' + file)
            for line in f:
                if line[:3] == 'SEX':
                    speakers.add((dir, line[4:5]))
            break

malecount = math.floor(spk_count/2)
femalecount = math.ceil(spk_count/2)

male_speakers = set()
female_speakers = set()
spk_list = list(speakers)
while len(male_speakers) < malecount:
    val = randint(0,len(spk_list)-1)
    spk = spk_list[val]
    if spk[1] == "M":
        male_speakers.add(spk)

while len(female_speakers) < femalecount:
    val = randint(0,len(spk_list)-1)
    spk = spk_list[val]
    if spk[1] == "F":
        female_speakers.add(spk)

male_speakers |= female_speakers

print(male_speakers)
# /tudelft.net/staff-bulk/ewi/insy/SpeechLab/corpora/mandarin/aidatatang_200zh/corpus/train