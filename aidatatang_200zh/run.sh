#!/bin/bash

# Copyright 2019 Beijing DataTang Tech. Co. Ltd. (Author: Liyuan Wang)
#           2017 Hui Bu
#           2017 Jiayu Du
#           2017 Xingyu Na
#           2017 Bengu Wu
#           2017 Hao Zheng
# Apache 2.0

# This is a shell script, but it's recommended that you run the commands one by
# one by copying and pasting into the shell.
# Caution: some of the graph creation steps use quite a bit of memory, so you
# should run this on a machine that has sufficient memory.

feats_nj=2
train_nj=2
decode_nj=2
stage=1
stop_stage=2
decode_stage=0

. ./cmd.sh ## You'll want to change cmd.sh to something that will work on your system.
           ## This relates to the queue.
# . ./cmd_local.sh
. ./utils/parse_options.sh
. ./path.sh
set -e
# . ./path_local.sh
# Acoustic model parameters
numLeavesTri1=2500
numGaussTri1=15000
numLeavesMLLT=2500
numGaussMLLT=15000
numLeavesSAT=2500
numGaussSAT=15000
numGaussUBM=400
numLeavesSGMM=7000
numGaussSGMM=9000


echo ============================================================================
echo "                Data & Lexicon & Language Preparation                     "
echo ============================================================================

# corpus directory
data=/tudelft.net/staff-bulk/ewi/insy/SpeechLab/corpora/mandarin/aidatatang_200zh

# Stage 0 takes a while to generate all the character translations, recommend pulling them from the .tar.gz's
if [ $stage -le 0 ] && [ $stop_stage -gt 0 ]; then

# Data Preparation: generate text, text_characters, wav.scp, utt2spk, spk2utt
    local/aidatatang_data_prep.sh $data/corpus $data/transcript || exit 1;
fi

if [ $stage -le 1 ] && [ $stop_stage -gt 1 ] ; then
# Lexicon Preparation: build a large lexicon that involves words in both the training and decoding
    local/aidatatang_prepare_dict.sh || exit 1;

    utils/prepare_lang.sh --position-dependent-phones false data/local/dict "SIL" data/local/lang data/lang || exit 1;
    # Prepare Language Stuff
    # Phone Sets, questions, L compilation

# G compilation, check LG composition
    local/aidatatang_format_data.sh

    echo ============================================================================
    echo "         MFCC Feature Extration & CMVN for Training and Test set          "
    echo ============================================================================
# # Now make MFCC plus pitch features, you might want to change this if you are only doing mfcc for your other dataset too.
# # mfccdir should be some place with a largish disk where you want to store MFCC features.
    mfccdir=mfcc
    for x in train dev test; do
    steps/make_mfcc_pitch.sh --write_utt2dur false --write_utt2num_frames false --cmd "$train_cmd" --nj 10 data/$x exp/make_mfcc/$x $mfccdir || exit 1;
    steps/compute_cmvn_stats.sh data/$x exp/make_mfcc/$x $mfccdir || exit 1;
    utils/fix_data_dir.sh data/$x || exit 1;
    done
fi
# This trains the monophone and triphone gmm-hmm things. These are the ones used by the timit recipe
# you might want to use the default aidatatang recipe for this part, which generates slightly different monophones.
# This will take forever the way it is set up, you can get away with commenting out the `steps/decode.sh` from the sections,
# This will not give you insight into the PER of the sections, but it will go a lot faster.
if [ $stage -le 2 ] && [ $stop_stage -gt 2 ];then
  echo ============================================================================
  echo "                     MonoPhone Training & Decoding                        "
  echo ============================================================================
  
  steps/train_mono.sh  --nj "$train_nj" --cmd "$train_cmd" data/train data/lang exp/mono
  
  utils/mkgraph.sh data/lang_test_bg exp/mono exp/mono/graph
  
#   steps/decode.sh --nj "$decode_nj" --cmd "$decode_cmd" --stage $decode_stage \
#    exp/mono/graph data/dev exp/mono/decode_dev
 
  steps/decode.sh --nj "$decode_nj" --cmd "$decode_cmd" \
   exp/mono/graph data/test exp/mono/decode_test

fi
if [ $stage -le 3 ] && [ $stop_stage -gt 3 ];then  
  echo ============================================================================
  echo "           tri1 : Deltas + Delta-Deltas Training & Decoding               "
  echo ============================================================================
  
  steps/align_si.sh --boost-silence 1.25 --nj "$train_nj" --cmd "$train_cmd" \
   data/train data/lang exp/mono exp/mono_ali
  
  # Train tri1, which is deltas + delta-deltas, on train data.
  steps/train_deltas.sh --cmd "$train_cmd" \
   $numLeavesTri1 $numGaussTri1 data/train data/lang exp/mono_ali exp/tri1
  
  utils/mkgraph.sh data/lang_test_bg exp/tri1 exp/tri1/graph
  
#   steps/decode.sh --nj "$decode_nj" --cmd "$decode_cmd" \
#    exp/tri1/graph data/dev exp/tri1/decode_dev
  
  steps/decode.sh --nj "$decode_nj" --cmd "$decode_cmd" \
   exp/tri1/graph data/test exp/tri1/decode_test
fi
if [ $stage -le 4 ] && [ $stop_stage -gt 4 ];then  
  echo ============================================================================
  echo "                 tri2 : LDA + MLLT Training & Decoding                    "
  echo ============================================================================
  
  steps/align_si.sh --nj "$train_nj" --cmd "$train_cmd" \
    data/train data/lang exp/tri1 exp/tri1_ali
  
  steps/train_lda_mllt.sh --cmd "$train_cmd" \
   --splice-opts "--left-context=3 --right-context=3" \
   $numLeavesMLLT $numGaussMLLT data/train data/lang exp/tri1_ali exp/tri2
  
  utils/mkgraph.sh data/lang_test_bg exp/tri2 exp/tri2/graph
  
#   steps/decode.sh --nj "$decode_nj" --cmd "$decode_cmd" \
#    exp/tri2/graph data/dev exp/tri2/decode_dev
  
  steps/decode.sh --nj "$decode_nj" --cmd "$decode_cmd" \
   exp/tri2/graph data/test exp/tri2/decode_test
fi
if [ $stage -le 6 ] && [ $stop_stage -gt 6 ];then  
  echo ============================================================================
  echo "              tri3 : LDA + MLLT + SAT Training & Decoding                 "
  echo ============================================================================
  
  # Align tri2 system with train data.
  steps/align_si.sh --nj "$train_nj" --cmd "$train_cmd" \
   --use-graphs true data/train data/lang exp/tri2 exp/tri2_ali
  
  # From tri2 system, train tri3 which is LDA + MLLT + SAT.
  steps/train_sat.sh --cmd "$train_cmd" \
   $numLeavesSAT $numGaussSAT data/train data/lang exp/tri2_ali exp/tri3
  
  utils/mkgraph.sh data/lang_test_bg exp/tri3 exp/tri3/graph
  
#   steps/decode_fmllr.sh --nj "$decode_nj" --cmd "$decode_cmd" \
#    exp/tri3/graph data/dev exp/tri3/decode_dev
  
  steps/decode_fmllr.sh --nj "$decode_nj" --cmd "$decode_cmd" \
   exp/tri3/graph data/test exp/tri3/decode_test
fi  
exit 0;
