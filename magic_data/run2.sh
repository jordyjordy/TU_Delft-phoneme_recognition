#!/bin/bash

# Also take a look at *_prepare_dict.sh
# Also take a look at *_prepare_lang.sh

./clean2.sh

echo ""
echo "***** Dictionary/Lexicon/Lang preparation ******"
echo ""

srcdir=data/
dir=data/local/dict
lmdir=data/local/nist_lm
tmpdir=data/local/lm_tmp

mkdir -p $dir $lmdir $tmpdir

[ -f path.sh ] && . ./path.sh

#(1) Dictionary preparation:
# data/local/dict format:
# - phones.txt
# - lexicon.txt
# - nonsilence_phones.txt
# - optional_silence.txt
# - silence_phones.txt
# - extra_questions.txt

# Phones.txt
cut -d' ' -f2- $srcdir/train/text | tr ' ' '\n' | sort -u > $dir/phones.txt

# Lexicon.txt
paste $dir/phones.txt $dir/phones.txt > $dir/lexicon.txt || exit 1;
echo "SIL SIL" >> $dir/lexicon.txt # As SIL should be/was ignored in the data prep

# Silence_phones.txt
echo SIL > $dir/silence_phones.txt

# Nonsilence_phones.txt
grep -v -F -f $dir/silence_phones.txt $dir/phones.txt > $dir/nonsilence_phones.txt 

# Optional_silence.txt
echo SIL > $dir/optional_silence.txt

# Extra_questions.txt
cat $dir/silence_phones.txt| awk '{printf("%s ", $1);} END{printf "\n";}' > $dir/extra_questions.txt || exit 1;
cat $dir/nonsilence_phones.txt | perl -e 'while(<>){ foreach $p (split(" ", $_)) {$p =~ m:^([^\d]+)(\d*)$: || die "Bad phone $_"; $q{$2} .= "$p "; } } foreach $l (values %q) {print "$l\n";}' >> $dir/extra_questions.txt || exit 1;


# (2) Create the phone bigram LM
# Should have IRSTLM instaled and exported as well as it's bin folder

cut -d' ' -f2- $srcdir/train/text | sed -e 's:^:<s> :' -e 's:$: </s>:' > $srcdir/lm_train.text || exit 1;

build-lm.sh -i $srcdir/lm_train.text -n 2 -o $tmpdir/lm_phone_bg.ilm.gz  || exit 1;

compile-lm $tmpdir/lm_phone_bg.ilm.gz -t=yes /dev/stdout | grep -v unk | gzip -c > $lmdir/lm_phone_bg.arpa.gz || exit 1;

echo ""
echo "  > Dictionary & Lexicon model preparation succeeded"
echo ""

utils/prepare_lang.sh --position-dependent-phones false data/local/dict "SIL" data/local/lang data/lang || exit 1;
echo ""
echo "  > Language preparation succeeded"
echo ""

local_script/magic-data_format_data.sh
echo ""
echo "  > Formating data succeeded"
echo ""


echo ""
echo "***** !!!FINISHED!!! Dictionary/Lexicon/Lang preparation ******"
echo ""
