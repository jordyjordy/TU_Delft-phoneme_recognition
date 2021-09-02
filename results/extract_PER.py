# import matplotlib.pyplot as plt
# import numpy as np
from os import listdir


def get_per(file):
    f = open(file)
    correct = {}
    substitution = {}
    deletion = {}
    insertion = {}
    total = 0
    for line in f:
        parts = line.split()
        total = total + int(parts[3])
        if parts[1][-1].isdigit():
            parts[1] = parts[1][:-1]
        if parts[2][-1].isdigit():
            parts[2] = parts[2][:-1]
        if parts[0] == "correct":
            if parts[1] in correct:
                correct[parts[1]] = correct[parts[1]] + int(parts[3])
            else:
                correct[parts[1]] = int(parts[3])
        if parts[0] == "deletion":
            if parts[1] in deletion:
                deletion[parts[1]] = deletion[parts[1]] + int(parts[3])
            else:
                deletion[parts[1]] = int(parts[3])
        if parts[0] == "insertion":
            if parts[1] in insertion:
                insertion[parts[2]] = insertion[parts[2]] + int(parts[3])
            else:
                insertion[parts[2]] = int(parts[3])
        if parts[0] == "substitution":
            if parts[1] == parts[2]:
                if parts[1] in correct:
                    correct[parts[1]] = correct[parts[1]] + int(parts[3])
                else:
                    correct[parts[1]] = int(parts[3])
            else:
                if parts[1] in substitution:
                    substitution[parts[1]] = substitution[parts[1]] + int(parts[3])
                else:
                    substitution[parts[1]] = int(parts[3])
    contribution_to_PER = {}
    PER = {}
    options = list(substitution.keys()) + list(deletion.keys()) + list(insertion.keys()) + list(correct.keys())
    options = set(options)
    for x in options:
        if x not in substitution:
            substitution[x] = 0
        if x not in deletion:
            deletion[x] = 0
        if x not in insertion:
            insertion[x] = 0
        if x not in correct:
            correct[x] = 0
        partsum = substitution[x] + deletion[x] + insertion[x]
        PER[x] = (partsum / float(substitution[x] + deletion[x] + correct[x]))
        contribution_to_PER[x] = (float(partsum) / (total - sum(list(correct.values()))))  # * PER
    # print(PER)
    # print(contribution_to_PER)
    # sorted_values = sorted(PER.values(), reverse=True)
    sorted_contribution_values = sorted(contribution_to_PER.values(), reverse=True)
    sorted_contribution_to_PER = {}
    sorted_PER = {}

    for i in sorted_contribution_values:
        for k in list(contribution_to_PER.keys()):
            if contribution_to_PER[k] == i:
                sorted_contribution_to_PER[k] = contribution_to_PER[k]
    keys = sorted_contribution_to_PER.keys()
    for k in keys:
        for i in list(PER.values()):
            if PER[k] == i:
                sorted_PER[k] = PER[k]
    # print(sorted_contribution_to_PER)
    avgErr = sum(list(substitution.values())) + sum(list(deletion.values())) + sum(list(insertion.values()))

    avgPer = avgErr / float(avgErr + sum(list(correct.values())) - sum(list(insertion.values())))
    return sorted_PER, sorted_contribution_to_PER, avgPer


if __name__ == '__main__':
    mainpath = './exp/chain/'

    for path in listdir('./exp/chain/'):
        if "tdnn" in path:
            file = mainpath + path + '/decode_test/scoring_kaldi/wer_details/ops'
            res = get_per(file)
            avg = ""
            avg += 'average , ' + str(round(res[2] * 100, 1)) + ' ,' + str(round(100/float(len(res[0].keys())), 1)) 
            #print('\hline')
	    print(path)
	    #print('\hline')
            print(avg)
	    #print('\hline')
            avg_per = 100/float(len(res[0].keys()))
            avg_contrib = res[2]

            for i in range(len(res[0].keys())):
                if list(res[0].values())[i] < avg_contrib or list(res[1].values())[i]*100 < avg_per:
                    continue
                line = ""
                phon = list(res[0].keys())[i]
                num1 = round(list(res[0].values())[i] * 100, 1)
                num2 = round(list(res[1].values())[i] * 100, 1)
                line += phon + " , " + str(num1) + "," + str(num2) 
                print(line)

	    #print('\hline')

