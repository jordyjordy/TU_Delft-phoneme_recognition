#!/bin/bash

#
# Copyright 2013 Bagher BabaAli,
#           2014-2017 Brno University of Technology (Author: Karel Vesely)
#
# TIMIT, description of the database:
# http://perso.limsi.fr/lamel/TIMIT_NISTIR4930.pdf
#
# Hon and Lee paper on TIMIT, 1988, introduces mapping to 48 training phonemes,
# then re-mapping to 39 phonemes for scoring:
# http://repository.cmu.edu/cgi/viewcontent.cgi?article=2768&context=compsci
#
feats_nj=10
train_nj=30
decode_nj=5
stage=1
stop_stage=2
decode_stage=0
. ./cmd.sh
. ./utils/parse_options.sh
[ -f path.sh ] && . ./path.sh
set -e

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
#timit=/export/corpora5/LDC/LDC93S1/timit/TIMIT # @JHU
timit=/tudelft.net/staff-bulk/ewi/insy/SpeechLab/corpora/english//TIMIT # @TU Deoft
if [ $stage -le 0 ] && [ $stop_stage -gt 0 ];then
  local/timit_data_prep.sh $timit || exit 1
  local/removesil.sh || exit 1;  
  local/timit_prepare_dict.sh
  
  # Caution below: we remove optional silence by setting "--sil-prob 0.0",
  # in TIMIT the silence appears also as a word in the dictionary and is scored.
  # EDIT: in this specific instance the silences are removed from the transcript
  utils/prepare_lang.sh --position-dependent-phones false --num-sil-states 3 \
   data/local/dict "sil" data/local/lang_tmp data/lang
  
  local/timit_format_data.sh
  
  echo ============================================================================
  echo "         MFCC Feature Extration & CMVN for Training and Test set          "
  echo ============================================================================
  
  # Now make MFCC features.
  mfccdir=mfcc
  
  
  for x in train dev test; do
    steps/make_mfcc.sh --cmd "$train_cmd" --nj $feats_nj data/$x exp/make_mfcc/$x $mfccdir
    steps/compute_cmvn_stats.sh data/$x exp/make_mfcc/$x $mfccdir
  done
fi
if [ $stage -le 1 ] && [ $stop_stage -gt 1 ];then
  echo ============================================================================
  echo "                     MonoPhone Training & Decoding                        "
  echo ============================================================================
  
  steps/train_mono.sh  --nj "$train_nj" --cmd "$train_cmd" data/train data/lang exp/mono
  
  utils/mkgraph.sh data/lang_test_bg exp/mono exp/mono/graph
  
  # steps/decode.sh --nj "$decode_nj" --cmd "$decode_cmd" --stage $decode_stage \
  #  exp/mono/graph data/dev exp/mono/decode_dev
 
  steps/decode.sh --nj "$decode_nj" --cmd "$decode_cmd" \
   exp/mono/graph data/test exp/mono/decode_test
  
  echo ============================================================================
  echo "           tri1 : Deltas + Delta-Deltas Training & Decoding               "
  echo ============================================================================
  
  steps/align_si.sh --boost-silence 1.25 --nj "$train_nj" --cmd "$train_cmd" \
   data/train data/lang exp/mono exp/mono_ali
  
  # Train tri1, which is deltas + delta-deltas, on train data.
  steps/train_deltas.sh --cmd "$train_cmd" \
   $numLeavesTri1 $numGaussTri1 data/train data/lang exp/mono_ali exp/tri1
  
  utils/mkgraph.sh data/lang_test_bg exp/tri1 exp/tri1/graph
  
  # steps/decode.sh --nj "$decode_nj" --cmd "$decode_cmd" \
  #  exp/tri1/graph data/dev exp/tri1/decode_dev
  
  steps/decode.sh --nj "$decode_nj" --cmd "$decode_cmd" \
   exp/tri1/graph data/test exp/tri1/decode_test
  
  echo ============================================================================
  echo "                 tri2 : LDA + MLLT Training & Decoding                    "
  echo ============================================================================
  
  steps/align_si.sh --nj "$train_nj" --cmd "$train_cmd" \
    data/train data/lang exp/tri1 exp/tri1_ali
  
  steps/train_lda_mllt.sh --cmd "$train_cmd" \
   --splice-opts "--left-context=3 --right-context=3" \
   $numLeavesMLLT $numGaussMLLT data/train data/lang exp/tri1_ali exp/tri2
  
  utils/mkgraph.sh data/lang_test_bg exp/tri2 exp/tri2/graph
  
  # steps/decode.sh --nj "$decode_nj" --cmd "$decode_cmd" \
  #  exp/tri2/graph data/dev exp/tri2/decode_dev
  
  steps/decode.sh --nj "$decode_nj" --cmd "$decode_cmd" \
   exp/tri2/graph data/test exp/tri2/decode_test
  
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
  
  # steps/decode_fmllr.sh --nj "$decode_nj" --cmd "$decode_cmd" \
  #  exp/tri3/graph data/dev exp/tri3/decode_dev
  
  steps/decode_fmllr.sh --nj "$decode_nj" --cmd "$decode_cmd" \
   exp/tri3/graph data/test exp/tri3/decode_test
fi  
exit 0 # From this point you can run Karel's DNN : local/nnet/run_dnn.sh
