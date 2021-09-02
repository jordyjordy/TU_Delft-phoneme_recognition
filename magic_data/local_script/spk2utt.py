#!/bin/python

pathFile="data/test/utt2spk"

file = open(pathFile,"rt")

cfile = file.readlines()

dict_p = {}
for line in cfile:
    p = line.split()
    utt = p[0]
    spk = p[1]
    if not( spk in dict_p.keys()):
        dict_p[spk]=[]
    dict_p[spk].append(utt)

file.close()

pathNewFile = "spk2utt"
file2 = open(pathNewFile,"a")

for item in dict_p.items():
    print(item)
    spk = item[0]
    arr = sorted(set(item[1]))
    file2.write(item[0]+" "+" ".join(arr)+"\n")

file2.close()

