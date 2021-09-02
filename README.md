# TU_Delft-phoneme_recognition
This Repository contains the setup and results of performing phoneme recognition on 4 different datasets using TDNN-BLSTM and TDNN-OPGRU networks.

The datasets are:

- Timit: https://catalog.ldc.upenn.edu/LDC93S1 (English prepared speech)
- Buckeye: https://buckeyecorpus.osu.edu/ (English conversational/spontaneous speech)
- Aidatatang_200zh: http://www.openslr.org/62/ (Mandarin prepared speech)
- Magic data: https://catalog.ldc.upenn.edu/LDC2019S23 (Mandarin conversational/spontaneous speech)

Of the Buckeye and Aidatatang_200zh set two other subsets were also made with a smaller training set to match that of the dataset for the other speech style for that respective language.

## General Data Preparation

This experiment focusses on phonemes, so non linguistic symbols such as `SIL` or `SPN` are removed from the transcript. For each data set will be indicated what symbols were removed/ignored in the transcripts, as well as other preparations that are made. 

All of the preparation, training, decoding and scoring was done with the Kaldi framework 

https://kaldi-asr.org/

## Data sets

### Timit

**Removed Symbols:** `sil, spn`

**Training duration:** 188.7 minutes

#### Train test split

No specific preparation steps were made to Timit, the default supplied training and test sets were used.

### Buckeye

Other than removed symbols, buckeye sometimes indicates nasalized sounds by adding an n (for example `aan` instead of `aa`) these have been replaced back to their normal symbols.

**Removed Symbols:** `<EXCLUDE>, <EXCLUDE-name>, <exclude-Name>, IVER, LAUGH, NOISE, SIL, UNKNOWN, VOCNOISE, IVER-LAUGH`

**Training duration:** 1057.8 minutes

#### Training set split

The test set was randomly picked such that it contains two old  and two young female speakers, and two old and two young male speakers, as indicated by the dataset. The remainder was used as the training set.

**Training set:**

`"s01" "s02" "s03" "s04" "s05" "s06" "s07" "s08" "s10" "s11" "s12" "s13" "s14" "s17" "s18" "s20" "s21" "s22" "s23" "s24" "s25" "s28" "s29" "s31" "s32" "s33" "s34" "s36" "s37" "s38" "s39" "s40"` 

**Test set:**

`"s09" "s15" "s16" "s19" "s26" "s27" "s30" "s35"`

#### segmentation

Because the buckeye segments are too large for Kaldi, the transcripts have to be further segmented. This is done by creating a segment whenever one of the removed symbols occurs, with the exception of `SIL`

### Buckeye_small

Buckeye small was prepared as a smaller version of buckeye that has a similar training duration to the timit data set.

Other than removed symbols, buckeye sometimes indicates nasalized sounds by adding an n (for example `aan` instead of `aa`) these have been replaced back to their normal symbols.

**Removed Symbols:** `<EXCLUDE>, <EXCLUDE-name>, <exclude-Name>, IVER, LAUGH, NOISE, SIL, UNKNOWN, VOCNOISE, IVER-LAUGH`

**Training duration:** 178.3 minutes

#### Training set split

The training set was randomly selected to have an even amount of male and female speakers, and at least one old and one young male and female speaker. The same test set as for the full buckeye set is used.

**Training set:**

`"s02" "s06" "s07" "s21" "s22" "s34"`

**Test set:**

`"s09" "s15" "s16" "s19" "s26" "s27" "s30" "s35"`

#### segmentation

Because the buckeye segments are too large for Kaldi, the transcripts have to be further segmented. This is done by creating a segment whenever one of the removed symbols occurs, with the exception of `SIL`

### Aidatatang_200zh

No symbols are removed from the Aidatatang set, however, since the set does not include phoneme transcriptions these were generated using tools included in the Kaldi Aidatatang_200zh folder for normal ASR.

Because of training size, the Aidatatang_200zh configurations were run with a multi-GPU setup, using 4 GPUs at a time rather than 1 for training.

**Removed symbols:** -

**Training duration:** 8396.1 minutes (139.9 hours)

#### Training test split

The normal training and test set were used for this data set

### Aidatatang_small

This set is prepared the same way as the full Aidatatang set, but uses a subset of the speakers for training to match the duration of Magic Data.

No symbols are removed from the Aidatatang set, however, since the set does not include phoneme transcriptions these were generated using tools included in the Kaldi Aidatatang_200zh folder for normal ASR.

**Removed symbols:** -

**Training duration:** 429.5 minutes

#### Training test split

The full test set was used, however for training a subset was used:

`G0187, G6403, G1517, G4429, G1111, G1386, G1685, G0430, G0141, G5590, G2448, G1144, G3516, G2330, G2246, G0283, G0889, G2270, G1781, G1834, G4507`

This set was randomly selected but had as criteria a balanced amount of male and female speakers, because the number of speakers is odd, there is one more female speaker.

### Magic Data

Because magic data's transcriptions are character-level rather than word-level, a tool called `Jieba` is used to make an estimate of how the transcription should be split up into worlds. https://github.com/fxsjy/jieba.

Afterwards the words were translated into phoneme sequences using tools supplied in Kaldi, in the same way as with the Aidatatang data sets.

**Removed symbols:** `[SONANT] [UNK] [LAUGH] [ENS]`

**Training duration:** 433.5 minutes

#### **Training test split**

Because no per-speaker information could be found for magic data, the first 48 speakers were used for training, and the last 12 speakers were used for testing (`SPK001 - SPK048`  and `SPK049 - SPK060` respectively).



## Network Configurations

The networks configurations can be found in the `/networks` folder, The variables that were altered per run can be found in the `/results/results.xlsx`file. 

Some general parameters that were fixed throughout the different networks, these can all be found more elaborately in the `/networks` folder.

- Dropout Schedule: `0,0@0.20,0.3@0.50,0`
- Epochs: 6
- L2 Regularisation: 0.00005
- Mini-batch: 64 (this resulted in less crashes than 128)

#### Layer configuration

The general layer configuration for both TDNN-BLSTM and TDNN-OPGRU networks is 3 TDNN layer, followed by a BLSTM or OPGRU later. Afterwards a pattern of 2 TDNN layers and 1 BLSTM or OPGRU layer repeats depending on layer count. 



## Results

The results of this research can be found in the `/results/results.xlsx`file. Here are also results included from the GMM-HMM model used to generate the forced alignments for the networks, as well as results of dutch prepared and spontaneous speech results from another research by Robert Levenbach: https://repository.tudelft.nl/islandora/object/uuid%3Ae3a1187e-0e3c-4013-91aa-cfc3767aae13.


Because there are some details missing from the paper by Robert Levenbach it is not completely clear which network configurations these results best relate to, so displayed next to the ones it could match to.



