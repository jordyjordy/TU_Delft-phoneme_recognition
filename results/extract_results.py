import os

rootdir = './exp/chain'
subpath = 'decode_test/scoring_kaldi/best_wer'
for file in os.listdir(rootdir):
    d = os.path.join(rootdir, file)
    if os.path.isdir(d):
        if "tdnn" in d:
            fullpath = os.path.join(d, subpath)
            if os.path.isfile(fullpath):
                f = open(fullpath)
                line = f.readline()
                res = line.split(" ")
                print(file +": " + res[1])

