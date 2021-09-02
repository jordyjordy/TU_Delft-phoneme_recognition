#!/bin/bash

echo ""
echo "***** Extract MFCC from speech recordings ******"
echo ""

./clean3.sh
which flac && echo "    > flac is present continue" || exit 1;

. ./path.sh
. ./cmd.sh
set -e

utils/fix_data_dir.sh data/train || exit 1;
utils/fix_data_dir.sh data/test  || exit 1;
echo ""
echo "  > Used 'utils/fix_data_dir.sh' on data/{train,test} $x"
echo ""


mfccdir=mfcc
for x in train test; do
    steps/make_mfcc_pitch.sh --write_utt2dur false --write_utt2num_frames false --cmd "$train_cmd" --nj 10 data/$x exp/make_mfcc/$x $mfccdir || exit 1;
    echo ""
    echo "  > Completed make_mffc_pitch for $x"
    echo ""
    steps/compute_cmvn_stats.sh data/$x exp/make_mfcc/$x $mfccdir || exit 1;
    echo ""
    echo "  > Completed compute_cmvn_stats for $x"
    echo ""
    utils/fix_data_dir.sh data/$x || exit 1;
    echo ""
    echo "  > Completed fix_data_dir for $x"
    echo ""
done

echo "***** !!!FINSIHED!!! Extract MFCC from speech recordings ******"