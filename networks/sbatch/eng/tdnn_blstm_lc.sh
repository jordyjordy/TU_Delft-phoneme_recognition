bash networks/run_tdnn_blstm_3_1.sh --stage 12 --stop-stage 16 --decode-nj 8 --lr-initial 0.05 --lr-final 0.005 --affix lc1 --linear-layer-dim 256 --layer-dim 1024 --input-dim 40
bash networks/run_tdnn_blstm_5_2.sh --stage 12 --stop-stage 16 --decode-nj 8 --lr-initial 0.05 --lr-final 0.005 --affix lc2 --linear-layer-dim 256 --layer-dim 1024 --input-dim 40
bash networks/run_tdnn_blstm_9_4.sh --stage 12 --stop-stage 16 --decode-nj 8 --lr-initial 0.05 --lr-final 0.005 --affix lc4 --linear-layer-dim 256 --layer-dim 1024 --input-dim 40
