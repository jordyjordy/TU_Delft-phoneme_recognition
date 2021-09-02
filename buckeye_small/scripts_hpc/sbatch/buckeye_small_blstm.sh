#!/bin/sh
#you can control the resources and scheduling with '#SBATCH' settings
# (see 'man sbatch' for more information on setting these parameters)
# The default partition is the 'general' partition
#SBATCH --partition=general
# The default Quality of Service is the 'short' QoS (maximum run time: 4 hours)
#SBATCH --qos=long
# The default run (wall-clock) time is 1 minute
#SBATCH --time=10:00:00
# The default number of parallel tasks per job is 1
#SBATCH --ntasks=1
# Request 1 CPU per active thread of your program (assume 1 unless you specifically set this)
# The default number of CPUs per task is 1 (note: CPUs are always allocated per 2)
#SBATCH --cpus-per-task=10
# The default memory per node is 1024 megabytes (1GB) (for multiple tasks, specify --mem-per-cpu instead)
#SBATCH --mem=16G
# Set mail type to 'END' to receive a mail when the job finishes
# Do not enable mails when submitting large numbers (>20) of jobs at once
#SBATCH --gres=gpu
#SBATCH --mail-type=ALL
#SBATCH --exclude=insy[11-14]
# Data preparation, phoneme label generation for subsequent DNN training
#srun bash run.sh --stage 1 --stop-stage 2  --train-nj 4 --decode-nj 8

# DNN training, first run run_ivector_common.sh, then run_chain_common.sh, finally run run_tdnn_lstm_1c.sh
#srun bash local/nnet3/run_ivector_common.sh --stage 0 --stop-stage 8 --nj 4 
#srun bash local/chain/run_chain_common.sh --stage 11 --stop-stage  14
##srun bash networks/run_tdnn_opgru_7_3_1024_256.sh --stage 12 --stop-stage 16 --nj-initial 1 --nj-final 1 --num-epochs 6 --train-stage -10 --lr-initial 0.0005 --lr-final 0.00005 --input-dim 40
#srun bash networks/run_tdnn_blstm_7_3.sh --stage 12 --stop-stage 16 --decode-nj 8 --lr-initial 0.1 --lr-final 0.01 --affix tr1 --linear-layer-dim 256 --layer-dim 1024 --input-dim 40
#srun bash networks/run_tdnn_blstm_7_3.sh --stage 12 --stop-stage 16 --decode-nj 8 --lr-initial 0.05 --lr-final 0.005 --affix tr2 --linear-layer-dim 256 --layer-dim 1024 --input-dim 40

#srun bash networks/sbatch/eng/tdnn_blstm_tr.sh
#srun bash networks/sbatch/eng/tdnn_blstm_rec.sh
#srun bash networks/run_tdnn_blstm_7_3.sh --stage 14 --stop-stage 16 --decode-nj 8 --lr-initial 0.05 --lr-final 0.005 --affix rec4 --linear-layer-dim 512 --layer-dim 1024 --input-dim 40
#srun bash networks/sbatch/eng/tdnn_blstm_ly.sh
#srun bash networks/sbatch/eng/tdnn_blstm_lc.sh

#srun bash networks/run_tdnn_blstm_7_3.sh --stage 12 --stop-stage 16 --decode-nj 8 --lr-initial 0.05 --lr-final 0.005 --affix ly1 --linear-layer-dim 256 --layer-dim 2048 --input-dim 40
#srun bash networks/run_tdnn_blstm_5_2.sh --stage 12 --stop-stage 16 --decode-nj 8 --lr-initial 0.05 --lr-final 0.005 --affix lc2 --linear-layer-dim 256 --layer-dim 1024 --input-dim 40
srun bash networks/run_tdnn_blstm_9_4.sh --stage 12 --stop-stage 16 --decode-nj 8 --lr-initial 0.05 --lr-final 0.005 --affix lc4 --linear-layer-dim 256 --layer-dim 1024 --input-dim 40

# Phoneme recognition with a well-trained DNN based phoneme recognition model:
#srun bash local/chain/tuning/run_tdnn_lstm_1a.sh --stage 14 --stop-stage 16 --decode-nj 4 #--num-epochs 12 --train-stage 26 #  --decode-iter 10 

# To train a different architecture just create your own .sh file like local/chain/tuning/run_tdnn_XXX.sh, and then train and decode with your .sh file.
# In the given dir, you will see run_tdnn_lstm_1a.sh, run_tdnn_lstm_1c.sh and run_tdnn_blstm_1a.sh. Feel free to try and compare them
# Note: You do not need to re-run run_ivector_common.sh, run_chain_common.sh before running your own .sh file
