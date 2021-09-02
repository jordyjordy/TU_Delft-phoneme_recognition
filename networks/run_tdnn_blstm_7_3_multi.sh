#!/bin/bash
# _1c.sh is like _1a.sh but with a much smaller neural network model 

# training acoustic model and decoding:
#     local/chain/tuning/run_tdnn_lstm_1a.sh
# System                      tdnn_lstm1a_sp

set -e

# configs for 'chain'
stop_stage=13
stage=12
train_stage=-10
get_egs_stage=-10
speed_perturb=true
affix=7_3
decode_iter=
decode_nj=50
decode_stage=0


# configs for TDNN-LSTM networks
linear_layer_dim=64
layer_dim=256
input_dim=43
# LSTM training options
frames_per_chunk=140,100,160
frames_per_chunk_primary=$(echo $frames_per_chunk | cut -d, -f1)
chunk_left_context=40
chunk_right_context=0
xent_regularize=0.025
self_repair_scale=0.00001
label_delay=5
# decode options
extra_left_context=50
extra_right_context=50
num_epochs=6
dropout_schedule='0,0@0.20,0.3@0.50,0'
nj_initial=4
nj_final=4
lr_initial=0.001
lr_final=0.0001

remove_egs=false
common_egs_dir="exp/chain/tdnn_blstm${affix}_sp/egs/"
nnet3_affix= #_cleaned
# End configuration section.
echo "$0 $@"  # Print the command line for logging

. ./cmd.sh
. ./path.sh
. ./utils/parse_options.sh

if [ ! -d $common_egs_dir ]; then
  echo "directory $common_egs_dir not found, setting to null"
  common_egs_dir=""
fi
if ! cuda-compiled; then
  cat <<EOF && exit 1
This script is intended to be used with GPUs but you have not compiled Kaldi with CUDA
If you want to use GPUs (and have them), go to src/, and configure and make on a machine
where "nvcc" is installed.
EOF
fi

# The iVector-extraction and feature-dumping parts are the same as the standard
# nnet3 setup, and you can skip them by setting "--stage 8" if you have already
# run those things.

suffix=
if [ "$speed_perturb" == "true" ]; then
  suffix=_sp
fi

gmm=tri3 #6b_cleaned
dir=exp/chain${nnet3_affix}/tdnn_blstm${affix}${suffix}
train_set=train #_960_cleaned
ali_dir=exp/${gmm}_ali_${train_set}_sp #_comb
tree_dir=exp/chain${nnet3_affix}/tree #${tree_affix:+_$tree_affix}
lang=data/lang_chain
train_data_dir=data/${train_set}_sp_hires #_comb
lores_train_data_dir=data/${train_set}_sp #_comb
train_ivector_dir=exp/nnet3${nnet3_affix}/ivectors_${train_set}_sp_hires #_comb
lat_dir=exp/chain${nnet3_affix}/${gmm}_sp_lats

if [ $stage -le 12 ] && [ $stop_stage -gt 12 ] ; then
  echo "$0: creating neural net configs using the xconfig parser";

  num_targets=$(tree-info $tree_dir/tree |grep num-pdfs|awk '{print $2}')
  learning_rate_factor=$(echo "print (0.5/$xent_regularize)" | python)

  opts="l2-regularize=0.00005"
  linear_opts="orthonormal-constraint=1.0"
  lstm_opts="l2-regularize=0.00005 decay-time=40"
  output_opts="l2-regularize=0.00005 output-delay=$label_delay max-change=1.5 dim=$num_targets"


  mkdir -p $dir/configs
  cat <<EOF > $dir/configs/network.xconfig
  input dim=100 name=ivector
  input dim=$input_dim name=input

  fixed-affine-layer name=lda input=Append(-1,0,1,ReplaceIndex(ivector, t, 0)) affine-transform-file=$dir/configs/lda.mat delay=$label_delay

  # the first splicing is moved before the lda layer, so no splicing here
  relu-batchnorm-layer name=tdnn1 $opts dim=$layer_dim
  relu-batchnorm-layer name=tdnn2 $opts input=Append(-1,0,1) dim=$layer_dim
  relu-batchnorm-layer name=tdnn3 $opts dim=$layer_dim input=Append(-1,0,1)

  fast-lstmp-layer name=lstm1-forward input=tdnn3 cell-dim=$layer_dim recurrent-projection-dim=$linear_layer_dim non-recurrent-projection-dim=$linear_layer_dim delay=-3 dropout-proportion=0.0 $lstm_opts
  fast-lstmp-layer name=lstm1-backward input=tdnn3 cell-dim=$layer_dim recurrent-projection-dim=$linear_layer_dim non-recurrent-projection-dim=$linear_layer_dim delay=3 dropout-proportion=0.0 $lstm_opts
  
  relu-batchnorm-layer name=tdnn4 $opts input=Append(lstm1-forward,lstm1-backward,-3,0,3) dim=$layer_dim
  relu-batchnorm-layer name=tdnn5 $opts input=Append(-3,0,3) dim=$layer_dim
  
  fast-lstmp-layer name=lstm2-forward input=tdnn5 cell-dim=$layer_dim recurrent-projection-dim=$linear_layer_dim non-recurrent-projection-dim=$linear_layer_dim delay=-3 dropout-proportion=0.0 $lstm_opts
  fast-lstmp-layer name=lstm2-backward input=tdnn5 cell-dim=$layer_dim recurrent-projection-dim=$linear_layer_dim non-recurrent-projection-dim=$linear_layer_dim delay=3 dropout-proportion=0.0 $lstm_opts
  
  relu-batchnorm-layer name=tdnn6 $opts input=Append(lstm2-forward,lstm2-backward,-3,0,3) dim=$layer_dim
  relu-batchnorm-layer name=tdnn7 $opts input=Append(-3,0,3) dim=$layer_dim
  
  fast-lstmp-layer name=lstm3-forward input=tdnn7 cell-dim=$layer_dim recurrent-projection-dim=$linear_layer_dim non-recurrent-projection-dim=$linear_layer_dim delay=-3 dropout-proportion=0.0 $lstm_opts
  fast-lstmp-layer name=lstm3-backward input=tdnn7 cell-dim=$layer_dim recurrent-projection-dim=$linear_layer_dim non-recurrent-projection-dim=$linear_layer_dim delay=3 dropout-proportion=0.0 $lstm_opts
  

  output-layer name=output input=Append(lstm3-forward,lstm3-backward) include-log-softmax=false $output_opts

  output-layer name=output-xent input=Append(lstm3-forward,lstm3-backward) learning-rate-factor=$learning_rate_factor $output_opts
EOF
  steps/nnet3/xconfig_to_configs.py --xconfig-file $dir/configs/network.xconfig --config-dir $dir/configs/
fi

if [ $stage -le 13 ] && [ $stop_stage -gt 13 ] ; then
  if [[ $(hostname -f) == *.clsp.jhu.edu ]] && [ ! -d $dir/egs/storage ]; then
    utils/create_split_dir.pl \
      /export/c0{1,2,5,7}/$USER/kaldi-data/egs/swbd-$(date +'%m_%d_%H_%M')/s5c/$dir/egs/storage $dir/egs/storage
  fi
  
  steps/nnet3/chain/train.py --stage $train_stage \
    --cmd "$decode_cmd" \
    --feat.online-ivector-dir $train_ivector_dir \
    --feat.cmvn-opts "--norm-means=false --norm-vars=false" \
    --chain.xent-regularize $xent_regularize \
    --chain.leaky-hmm-coefficient 0.1 \
    --chain.l2-regularize 0.00005 \
    --chain.apply-deriv-weights false \
    --chain.lm-opts="--num-extra-lm-states=2000" \
    --trainer.dropout-schedule $dropout_schedule \
    --trainer.num-chunk-per-minibatch 64 \
    --trainer.frames-per-iter 1500000 \
    --trainer.max-param-change 2.0 \
    --trainer.num-epochs $num_epochs \
    --trainer.optimization.num-jobs-initial $nj_initial \
    --trainer.optimization.num-jobs-final $nj_final \
    --trainer.optimization.initial-effective-lrate $lr_initial \
    --trainer.optimization.final-effective-lrate $lr_final \
    --trainer.optimization.momentum 0.0 \
    --trainer.deriv-truncate-margin 8 \
    --egs.stage $get_egs_stage \
    --egs.opts "--frames-overlap-per-eg 0" \
    --egs.chunk-width $frames_per_chunk \
    --egs.chunk-left-context $chunk_left_context \
    --egs.chunk-right-context $chunk_right_context \
    --egs.chunk-left-context-initial 0 \
    --egs.chunk-right-context-final 0 \
    --egs.dir "$common_egs_dir" \
    --cleanup.remove-egs $remove_egs \
    --feat-dir $train_data_dir \
    --tree-dir $tree_dir \
    --lat-dir $lat_dir \
    --use-gpu wait \
    --dir $dir  || exit 1;
fi


if [ $stage -le 14 ]  && [ $stop_stage -gt 14 ]; then
  # Note: it might appear that this $lang directory is mismatched, and it is as
  # far as the 'topo' is concerned, but this script doesn't read the 'topo' from
  # the lang directory.
  utils/mkgraph.sh --self-loop-scale 1.0 --remove-oov data/lang_test_bg $tree_dir $tree_dir/graph
fi
graph_dir=$tree_dir/graph #_tgsmall

iter_opts=
if [ ! -z $decode_iter ]; then
  iter_opts=" --iter $decode_iter "
  scoring_opts=" --iter $decode_iter "
fi
if [ $stage -le 15 ] && [ $stop_stage -gt 15 ]; then
  rm $dir/.error 2>/dev/null || true
  for decode_set in test; do
      steps/nnet3/decode.sh --acwt 1.0 --post-decode-acwt 10.0 \
          --stage $decode_stage \
          --nj $decode_nj --cmd "$decode_cmd" $iter_opts \
          --scoring_opts "$scoring_opts" \
          --extra-left-context $extra_left_context \
          --extra-right-context $extra_right_context \
          --extra-left-context-initial 0 \
          --extra-right-context-final 0 \
          --frames-per-chunk "$frames_per_chunk_primary" \
          --online-ivector-dir exp/nnet3${nnet3_affix}/ivectors_${decode_set}_hires \
          $graph_dir data/${decode_set}_hires $dir/decode_${decode_set}${decode_iter:+_$decode_iter} || exit 1 #_tgsmall || exit 1
#      steps/lmrescore.sh --cmd "$decode_cmd" --self-loop-scale 1.0 data/lang_test_{tgsmall,tgmed} \
#          data/${decode_set}_hires $dir/decode_${decode_set}${decode_iter:+_$decode_iter}_{tgsmall,tgmed} || exit 1
#      steps/lmrescore_const_arpa.sh \
#          --cmd "$decode_cmd" data/lang_test_{tgsmall,tglarge} \
#          data/${decode_set}_hires $dir/decode_${decode_set}${decode_iter:+_$decode_iter}_{tgsmall,tglarge} || exit 1
#      steps/lmrescore_const_arpa.sh \
#          --cmd "$decode_cmd" data/lang_test_{tgsmall,fglarge} \
#          data/${decode_set}_hires $dir/decode_${decode_set}${decode_iter:+_$decode_iter}_{tgsmall,fglarge} || exit 1
  done
  if [ -f $dir/.error ]; then
    echo "$0: something went wrong in decoding"
    exit 1
  fi
fi

echo "$0: Succeeded"
