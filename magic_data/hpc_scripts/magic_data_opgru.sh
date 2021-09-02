#!/bin/sh
#you can control the resources and scheduling with '#SBATCH' settings
# (see 'man sbatch' for more information on setting these parameters)
# The default partition is the 'general' partition
#SBATCH --partition=general
# The default Quality of Service is the 'short' QoS (maximum run time: 4 hours)
#SBATCH --qos=long
# The default run (wall-clock) time is 1 minute
#SBATCH --time=32:00:00
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
#SBATCH --mail-type=NONE

#srun bash networks/run_tdnn_blstm_7_3.sh --stage 12 --stop-stage 16 --decode-nj 10 --lr-initial 0.05 --lr-final 0.005 --affix ly1 --linear-layer-dim 256 --layer-dim 2048 --input-dim 43
#srun bash networks/run_tdnn_blstm_3_1.sh --stage 12 --stop-stage 16 --decode-nj 10 --lr-initial 0.05 --lr-final 0.005 --affix lc1 --linear-layer-dim 256 --layer-dim 1024 --input-dim 43

#srun bash networks/run_tdnn_opgru_3_1.sh --stage 12 --stop-stage 16 --decode-nj 10 --lr-initial 0.05 --lr-final 0.005 --affix lc1 --linear-layer-dim 256 --layer-dim 1024 --input-dim 43

srun bash networks/sbatch/man/tdnn_opgru_tr.sh
srun bash networks/sbatch/man/tdnn_opgru_rec.sh
srun bash networks/sbatch/man/tdnn_opgru_ly.sh
srun bash networks/sbatch/man/tdnn_opgru_lc.sh


#srun bash networks/run_tdnn_opgru_7_3.sh --stage 12 --stop-stage 16 --decode-nj 10 --lr-initial 0.05 --lr-final 0.005 --affix tr2 --linear-layer-dim 256 --layer-dim 1024 --input-dim 43
#srun bash run.sh --stage 1 --stop-stage 3 --train-nj 10 --decode-nj 6
#srun bash local/nnet3/run_ivector_common.sh --stage 0 --stop-stage 8 --nj 4 
#srun bash local/chain/run_chain_common.sh --stage 11 --stop-stage  14

