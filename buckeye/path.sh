#export KALDI_ROOT=`pwd`/../../..
export KALDI_ROOT=/tudelft.net/staff-bulk/ewi/insy/SpeechLab/siyuanfeng/software/kaldi/ #`pwd`/../../..
export FST_ROOT=/scratch/siyuanfeng/software/kaldi
export IRSTLM=/scratch/siyuanfeng/software/kaldi/tools/irstlm
#[ -f $KALDI_ROOT/tools/env.sh ] && . $KALDI_ROOT/tools/env.sh
[ -f $FST_ROOT/tools/env.sh ] && . $FST_ROOT/tools/env.sh
export PATH=$PWD/utils/:$FST_ROOT/tools/openfst/bin:$PWD:$PATH
[ ! -f $KALDI_ROOT/tools/config/common_path.sh ] && echo >&2 "The standard file $KALDI_ROOT/tools/config/common_path.sh is not present -> Exit!" && exit 1
. $KALDI_ROOT/tools/config/common_path.sh
export LC_ALL=C

