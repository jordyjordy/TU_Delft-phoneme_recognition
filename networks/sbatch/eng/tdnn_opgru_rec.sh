bash networks/run_tdnn_opgru_7_3.sh --stage 12 --stop-stage 16 --decode-nj 8 --lr-initial 0.05 --lr-final 0.005 --affix rec1 --linear-layer-dim 64 --layer-dim 1024 --input-dim 40
bash networks/run_tdnn_opgru_7_3.sh --stage 12 --stop-stage 16 --decode-nj 8 --lr-initial 0.05 --lr-final 0.005 --affix rec2 --linear-layer-dim 128 --layer-dim 1024 --input-dim 40
bash networks/run_tdnn_opgru_7_3.sh --stage 12 --stop-stage 16 --decode-nj 8 --lr-initial 0.05 --lr-final 0.005 --affix rec4 --linear-layer-dim 512 --layer-dim 1024 --input-dim 40