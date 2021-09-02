#!/bin/bash

#TODO Check for "running from the project root folder"
#TODO Check for "u sure want to clean/wipe previous progress" (clean.sh)
#TODO modify transcribe_tool to match TEAMMATE recomendations.
#TODO add arguments support to local_script/main.py
#TODO add threads to local_script/main.py to speed up the Phoneme transcription
#TODO add arguments support to local_script/spk2utt.py

# Backups the previos data folder structure and creates a new one
# Make sure u want this, may take some time to regenerate Phonemes
#./clean.sh

echo ""
echo "***** DATA PREPARATION ******"
echo ""

# Create folder structure for Data preparation
mkdir data
mkdir data/train data/test
echo ""
echo "  > created data folder structure"
echo ""

# Create the Phonemes transcripts.
# check main.py for corpus paths
# check main.py for set intervals
# can take some time, be sure u want to redo
python3 local_script/main.py || exit 1;
echo ""
echo "  > Completed phoneme transcription"
echo ""


# Generate spk2utt, as alternative use spk2utt.py, but check for correct paths
utils/utt2spk_to_spk2utt.pl data/test/utt2spk > data/test/spk2utt || exit 1;
utils/utt2spk_to_spk2utt.pl data/train/utt2spk > data/train/spk2utt || exit 1;
echo ""
echo "  > Completed spk2utt generation for data/{train,test}"
echo ""

# Fix the data/{train,test} folders before continuing.
utils/fix_data_dir.sh data/train || exit 1;
utils/fix_data_dir.sh data/test  || exit 1;
echo ""
echo "  > Completed data/{train,test} folder FIX "
echo ""


echo ""
echo "***** !!!FINISHED!!! DATA PREPARATION ******"
echo ""