#!/bin/python
# -*- coding: utf-8 -*-
import os
import transcribe_tool
import sys
pathToCorpus            = sys.argv[1]
print(pathToCorpus)
# pathToCorpus_Lexicon    = pathToCorpus+"lexicon.txt"
pathToCorpus_TXT        = pathToCorpus+"data/TXT/"
pathToCorpus_FLAC       = pathToCorpus+"data/FLAC/"

pathToDataFolder = "data/"
pathToDataFolder_train = pathToDataFolder+"train/"
pathToDataFolder_test  = pathToDataFolder+"test/"

fs = sorted(os.scandir(pathToCorpus_TXT), key=lambda e: e.name)
trainSet = []
testSet = []
for entry in fs:
    try:
        if int(entry.name[-19:-16]) in range(0,49):
            trainSet.append(entry.name)
        if int(entry.name[-19:-16]) in range(49,61):
            testSet.append(entry.name)
    except:
        print('could not make integer?')
        print(entry)

# f_Lexicon  = open(pathToCorpus_Lexicon, "rt")
# c_Lexicon = f_Lexicon.readlines()
# f_Lexicon.close()


def main_func(dataFolder, dataSet):

    # For Training
    for entry in dataSet:
        #print("STARTED ENTRY:", entry)
        # (Text_Grid_File, StartTime, EndTime, Text_WORDS, Text_Phon)

        pathToCorpus_TXT_Grid = pathToCorpus_TXT+entry
        f_TXT_Grid = open(pathToCorpus_TXT_Grid, "rt", encoding='utf-8')
        c_TXT_Grid = f_TXT_Grid.readlines()
        f_TXT_Grid.close()
        res = transcribe_tool.transcribe(c_TXT_Grid, entry)
        for item in res:
            #print(item)
            filename = item[0][:-9] # get without .TextGrid
            foldername = item[0][:-16] # get Folder Name
            speaker = item[0][21:-9] # get only SPEAKER

            # Reorder utt_id so it passes the validation step
            mdt_prefix = filename[:16]
            mdt_number = filename[17:20]
            utt_id = mdt_prefix+"_"+speaker+"_"+mdt_number+"-"+str(item[1])+"-"+str(item[2]) # filename-startime-endtime

            # Segments  MDT_Conversation_001_SPK001-5.90-8.00 MDT_Conversation_001_SPK001 5.90 8.00
            f_segments  = open(dataFolder+"segments", "a")
            f_segments.write(utt_id+" "+filename+" "+str(item[1])+" "+str(item[2])+"\n")
            f_segments.close()

            # TEXT
            f_text      = open(dataFolder+"text", "a", encoding='utf-8')
            tempstring = "".join(item[3]).upper()
            f_text.write(utt_id+" " + tempstring +"\n")
            f_text.close()

            # UTT2SPK MDT_Conversation_001_SPK001-5.90-8.00 SPK001
            f_utt2spk = open(dataFolder+"utt2spk", "a", encoding='utf-8')
            f_utt2spk.write(utt_id+" "+speaker+"\n")
            f_utt2spk.close()

            # TESTING
            f_testing   = open(dataFolder+"test_python", "a", encoding='utf-8')
            f_testing.write(str(item)+"\n")
            f_testing.close()

        # WAV MDT_Conversation_001_SPK001 flac -c -d -s /tudelft.net/staff-bulk/ewi/insy/SpeechLab/corpora/mandarin/Magic_Chinese_Mandarin_Conversational_Speech/md_cmn_conversational_speech/data/FLAC/MDT_Conversation_001/MDT_Conversation_001_SPK001.flac |
        f_wav       = open(dataFolder+"wav.scp", "a")
        f_wav.write(filename+" flac -c -d -s " + pathToCorpus_FLAC + foldername +"/" + filename +".flac |" + "\n")
        f_wav.close()

        f_testing   = open(dataFolder+"test_python", "a")
        f_testing.write("******************Finished File "+ entry+ " ************************\n")
        f_testing.close()
        print("     +", entry)



main_func(pathToDataFolder_train,trainSet)
main_func(pathToDataFolder_test,testSet)





