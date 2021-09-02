#!/bin/bash

if [ $# -ne 1 ]; then
   echo "Argument should be the Timit corpus directory, see ../run.sh for example."
   exit 1;
fi

dir=`pwd`/data
stage=0
stop_stage=2
. path.sh # Needed for KALDI_ROOT
export PATH=$PATH:$KALDI_ROOT/tools/irstlm/bin
sph2pipe=$KALDI_ROOT/tools/sph2pipe_v2.5/sph2pipe

tmpdir=$(mktemp -d /tmp/kaldi.XXXX);
trap 'rm -rf "$tmpdir"' EXIT

lmdir=`pwd`/data/local/nist_lm
mkdir -p $dir $lmdir

if [ $stage -le 0 ] && [ $stop_stage -gt 0 ];then
#remove old files
rm -r "$dir"
mkdir -p "$dir/train"
mkdir -p "$dir/test"
mkdir -p "$dir/local/dict"
mkdir -p "$dir/lang"

#create new files
touch "$dir/train/segments"
touch "$dir/train/utt2spk"
touch "$dir/train/spk2utt"
touch "$dir/train/text"
touch "$dir/train/wav.scp"

touch "$dir/test/segments"
touch "$dir/test/utt2spk"
touch "$dir/test/spk2utt"
touch "$dir/test/text"
touch "$dir/test/wav.scp"

touch "$dir/local/dict/phones.txt"
touch "$dir/local/dict/phones.txt"
touch "$dir/local/dict/lexicon.txt"
touch "$dir/local/dict/nonsilence_phones.txt"
touch "$dir/local/dict/optional_silence.txt"
touch "$dir/local/dict/silence_phones.txt"
touch "$dir/local/dict/extra_questions.txt"

all_phonemes=()
special_phonemes=("<EXCLUDE>" "<EXCLUDE-name>" "<exclude-Name>" "IVER" "LAUGH" "NOISE" "SIL" "UNKNOWN" "VOCNOISE" "IVER-LAUGH")

old_IFS="$IFS"

train_split=("s01" "s02" "s03" "s04" "s05" "s06" "s07" "s08" "s10" "s11" "s12" "s13" "s14" "s17" "s18" "s20" "s21" "s22" "s23" "s24" "s25" "s28" "s29" "s31" "s32" "s33" "s34" "s36" "s37" "s38" "s39" "s40")
# train_split=("s01")
test_split=("s09" "s15" "s16" "s19" "s26" "s27" "s30" "s35")
# test_split=("s09")

array_contains () {
    local array="$1[@]"
    local seeking=$2
    local in=0
    for element in "${!array}"; do
        if [[ $element == "$seeking" ]]; then
            in=1
            break
        fi
    done
    return $in
}


# create segment file

for speaker in ${train_split[@]}; do
    start_segment="0.0"
    end_segment="0.0"
    segment_counter=000
    for x in $1/$speaker/*.phones; do
        echo "$x"

        fileWithExtension=$(basename $x);
        fileName=${fileWithExtension%.phones}
        pathAndFileName=${x%.phones}

        # Add to wav.scp
        echo "$fileName $pathAndFileName.wav" >> "$dir/train/wav.scp"

        IFS=$'\n'
        for line in $(sed -n '/{B_TRANS}/,/{E_TRANS}/p' $x); do
            IFS=$" "
            read -r timestamp y phone <<< $line
            # echo "${phone}"
            if [ "$phone" = "{B_TRANS}" ]; then
                start_segment="$timestamp"
                echo "Start Segment ${start_segment}"
            elif [ "$phone" = "{E_TRANS}" ]; then
                echo "End Segment and file"

                                #check if phonemes have been added since last segment
                                if [[ "$start_segment"  != "$end_segment" ]]; then
                    end_segment="$timestamp"
                                        utt_id="${fileName}""_"$(printf "%03d" "$segment_counter")

                                        # Segment file
                                        echo "$utt_id" "$fileName $start_segment $end_segment" >> "$dir/train/segments"
                                        segment_counter=0

                                        # Text file
                                        echo "$utt_id" "${current_phonemes[*]}" >> "$dir/train/text"
                                        current_phonemes=()
                                fi

                break
            elif [[ "$phone" =~ "<EXCLUDE>" ]] || [[ "$phone" =~ "<EXCLUDE-name>" ]] || [[ "$phone" =~ "<exclude-Name>" ]] || [[ "$phone" =~ "IVER" ]] || [[ "$phone" =~ "LAUGH" ]] || [[ "$phone" =~ "IVER-LAUGH" ]] || [[ "$phone" =~ "NOISE" ]] || [[ "$phone" =~ "UNKNOWN" ]] || [[ "$phone" =~ "VOCNOISE" ]]; then
                echo "found bad phoneme that has to be ignored ${phone}"
                if [[ "$start_segment"  == "$end_segment" ]]; then
                    start_segment="$timestamp" #Start from next phoneme
                else
                    #echo "End Segment"
                    utt_id="${fileName}""_"$(printf "%03d" "$segment_counter")

                    # Segment file
                    echo "$utt_id" "$fileName $start_segment $end_segment" >> "$dir/train/segments"
                    start_segment="$timestamp" #Start from next phoneme
                    ((segment_counter=segment_counter+1))

                    # Text file
                    echo "$utt_id" "${current_phonemes[*]}" >> "$dir/train/text"
                    current_phonemes=()
                fi
            else
                # Filter out unwanted suffixes
                #echo "test"
                filtered_phone="$(echo $phone | cut -d' ' -f1 | cut -d';' -f1 | cut -d'+' -f1)"
                #echo "$phone $filtered_phone"

                current_phonemes+=("${filtered_phone}") # Add current phoneme for TEXT file
                all_phonemes+=("${filtered_phone}")
            fi
            end_segment="$timestamp"
        done
    done
    echo "Done with speaker $speaker"
done


# create utt2spk
IFS=" "

while read line; do
        IFS=" "
        read -r utt_id filename start_time end_time <<< $line
        spk_id=${filename::3}
        echo $utt_id $spk_id >> "$dir/train/utt2spk"
done < "$dir/train/segments"

# create spk2utt
current_speaker="default"
list_of_utt=()
IFS=" "

while read line; do
        IFS=" "
        read -r utt_id spk_id <<< $line

    if [ "$current_speaker" = "default" ]; then
        current_speaker="$spk_id"
    fi

    if [[ "$current_speaker"  == "$spk_id" ]]; then
        list_of_utt+=("${utt_id}")
    else
        echo $current_speaker ${list_of_utt[*]} >> "$dir/train/spk2utt"
        current_speaker="$spk_id"
        list_of_utt=("${utt_id}")
    fi
done < "$dir/train/utt2spk"

#Print the last speaker
echo $current_speaker ${list_of_utt[*]} >> "$dir/train/spk2utt"

echo "==========================="
echo "Step 1 training split done!"
echo "==========================="

current_phonemes=()

for speaker in ${test_split[@]}; do
    start_segment="0.0"
    end_segment="0.0"
    segment_counter=000
    find $1/$speaker -iname '*.phones' -print0 | while read -d $'\0' x; do
        fileWithExtension=$(basename $x);
        fileName=${fileWithExtension%.phones}
        pathAndFileName=${x%.phones}

        # Add to wav.scp
        echo "$fileName $pathAndFileName.wav" >> "$dir/test/wav.scp"

        IFS=$'\n'
        for line in $(sed -n '/{B_TRANS}/,/{E_TRANS}/p' $x); do
            IFS=$" "
            read -r timestamp y phone <<< $line

            if [ "$phone" = "{B_TRANS}" ]; then
                start_segment="$timestamp"
                #echo "Start Segment"
            elif [ "$phone" = "{E_TRANS}" ]; then
                #echo "End Segment and file"

                                #check if phonemes have been added since last segment
                                if [[ "$start_segment"  != "$end_segment" ]]; then
                    end_segment="$timestamp"
                                        utt_id="${fileName}""_"$(printf "%03d" "$segment_counter")

                                        # Segment file
                                        echo "$utt_id" "$fileName $start_segment $end_segment" >> "$dir/test/segments"
                                        segment_counter=0

                                        # Text file
                                        echo "$utt_id" "${current_phonemes[*]}" >> "$dir/test/text"
                                        current_phonemes=()
                                fi

                break
            elif [[ "$phone" =~ "<EXCLUDE>" ]] || [[ "$phone" =~ "<EXCLUDE-name>" ]] || [[ "$phone" =~ "<exclude-Name>" ]] || [[ "$phone" =~ "IVER" ]] || [[ "$phone" =~ "LAUGH" ]] || [[ "$phone" =~ "IVER-LAUGH" ]] || [[ "$phone" =~ "NOISE" ]] || [[ "$phone" =~ "UNKNOWN" ]] || [[ "$phone" =~ "VOCNOISE" ]]; then

                if [[ "$start_segment"  == "$end_segment" ]]; then
                    start_segment="$timestamp" #Start from next phoneme
                else
                    #echo "End Segment"
                    utt_id="${fileName}""_"$(printf "%03d" "$segment_counter")

                    # Segment file
                    echo "$utt_id" "$fileName $start_segment $end_segment" >> "$dir/test/segments"
                    start_segment="$timestamp" #Start from next phoneme
                    ((segment_counter=segment_counter+1))

                    # Text file
                    echo "$utt_id" "${current_phonemes[*]}" >> "$dir/test/text"
                    current_phonemes=()
                fi
            else
                # Filter out unwanted suffixes
                #echo "test"
                filtered_phone="$(echo $phone | cut -d' ' -f1 | cut -d';' -f1 | cut -d'+' -f1)"
                #echo "$phone $filtered_phone"

                current_phonemes+=("${filtered_phone}") # Add current phoneme for TEXT file
                all_phonemes+=("${filtered_phone}")
            fi
            end_segment="$timestamp"
        done
    done
    echo "Done with speaker $speaker"
done

# create utt2spk
IFS=" "

while read line; do
        IFS=" "
        read -r utt_id filename start_time end_time <<< $line
        spk_id=${filename::3}
        echo $utt_id $spk_id >> "$dir/test/utt2spk"
done < "$dir/test/segments"

# create spk2utt
current_speaker="default"
list_of_utt=()
IFS=" "

while read line; do
        IFS=" "
        read -r utt_id spk_id <<< $line

    if [ "$current_speaker" = "default" ]; then
        current_speaker="$spk_id"
    fi

    if [[ "$current_speaker"  == "$spk_id" ]]; then
        list_of_utt+=("${utt_id}")
    else
        echo $current_speaker ${list_of_utt[*]} >> "$dir/test/spk2utt"
        current_speaker="$spk_id"
        list_of_utt=("${utt_id}")
    fi
done < "$dir/test/utt2spk"

#Print the last speaker
echo $current_speaker ${list_of_utt[*]} >> "$dir/test/spk2utt"

echo "==========================="
echo "Step 1 testing split done!"
echo "==========================="


#Sort the array of all phonemes and remove duplicates
IFS=$'\n'
unique_phonemes=( $(printf "%s\n" "${all_phonemes[@]}" | sort -u) )
IFS="$old_IFS"


# printf "%s\n" "${unique_phonemes[@]}" >> "$dir/local/dict/phones.txt"
# printf "SIL\n" >> "$dir/local/dict/phones.txt"

sed -e 's/\<SIL\>//g' $dir/train/text -i
sed -e 's/\<SIL\>//g' $dir/test/text -i
sed -e 's/\<aan\>/aa n/g' $dir/train/text -i
sed -e 's/\<aan\>/aa n/g' $dir/test/text -i
sed -e 's/\<aen\>/ae n/g' $dir/train/text -i
sed -e 's/\<aen\>/ae n/g' $dir/test/text -i
sed -e 's/\<aen\>/ae n/g' $dir/train/text -i
sed -e 's/\<aen\>/ae n/g' $dir/test/text -i
sed -e 's/\<ahn\>/ah n/g' $dir/train/text -i
sed -e 's/\<ahn\>/ah n/g' $dir/test/text -i
sed -e 's/\<aon\>/ao n/g' $dir/train/text -i
sed -e 's/\<aon\>/ao n/g' $dir/test/text -i
sed -e 's/\<awn\>/aw n/g' $dir/train/text -i
sed -e 's/\<awn\>/aw n/g' $dir/test/text -i
sed -e 's/\<ayn\>/ay n/g' $dir/train/text -i
sed -e 's/\<ayn\>/ay n/g' $dir/test/text -i
sed -e 's/\<eyn\>/ey n/g' $dir/train/text -i
sed -e 's/\<eyn\>/ey n/g' $dir/test/text -i
sed -e 's/\<uhn\>/uh n/g' $dir/train/text -i
sed -e 's/\<uhn\>/uh n/g' $dir/test/text -i
sed -e 's/\<own\>/ow n/g' $dir/train/text -i
sed -e 's/\<own\>/ow n/g' $dir/test/text -i
sed -e 's/\<oyn\>/oy n/g' $dir/train/text -i
sed -e 's/\<oyn\>/oy n/g' $dir/test/text -i
sed -e 's/\<uwn\>/uw n/g' $dir/train/text -i
sed -e 's/\<uwn\>/uw n/g' $dir/test/text -i
sed -e 's/\<ehn\>/eh n/g' $dir/train/text -i
sed -e 's/\<ehn\>/eh n/g' $dir/test/text -i
sed -e 's/\<ern\>/er n/g' $dir/train/text -i
sed -e 's/\<ern\>/er n/g' $dir/test/text -i
sed -e 's/\<uwn\>/uw n/g' $dir/train/text -i
sed -e 's/\<uwn\>/uw n/g' $dir/test/text -i
sed -e 's/\<hhn\>/hh n/g' $dir/train/text -i
sed -e 's/\<hhn\>/hh n/g' $dir/test/text -i
sed -e 's/\<ihn\>/ih n/g' $dir/train/text -i
sed -e 's/\<ihn\>/ih n/g' $dir/test/text -i
sed -e 's/\<iyn\>/iy n/g' $dir/train/text -i
sed -e 's/\<iyn\>/iy n/g' $dir/test/text -i
sed -e 's/[[:space:]]n[[:space:]]n/ n/g'  $dir/train/text -i
sed -e 's/[[:space:]]n[[:space:]]n/ n/g' $dir/test/text -i
sed -e s/\ \ */\ /g $dir/train/text -i
sed -e s/\ \ */\ /g $dir/train/text -i


cut -d' ' -f2- $dir/train/text | tr ' ' '\n' | sort -u > $dir/local/dict/phones.txt
sed -i '/^$/d' $dir/local/dict/phones.txt
#Lexicon
paste "$dir/local/dict/phones.txt" "$dir/local/dict/phones.txt" > "$dir/local/dict/lexicon.txt"
echo "SIL SIL" >> "$dir/local/dict/lexicon.txt"
#Silence
echo "SIL" > "$dir/local/dict/silence_phones.txt"
echo "SIL" > "$dir/local/dict/optional_silence.txt"

#Non-silence
grep -v -F -f "$dir/local/dict/silence_phones.txt" "$dir/local/dict/phones.txt" > "$dir/local/dict/nonsilence_phones.txt"

# A few extra questions that will be added to those obtained by automatically clustering
# the "real" phones.  These ask about stress; there's also one for silence.
cat "$dir/local/dict/silence_phones.txt" | awk '{printf("%s ", $1);} END{printf "\n";}' > "$dir/local/dict/extra_questions.txt" || exit 1;
cat "$dir/local/dict/nonsilence_phones.txt" | perl -e 'while(<>){ foreach $p (split(" ", $_)) {
  $p =~ m:^([^\d]+)(\d*)$: || die "Bad phone $_"; $q{$2} .= "$p "; } } foreach $l (values %q) {print "$l\n";}' \
 >> "$dir/local/dict/extra_questions.txt" || exit 1;

fi
if [ $stage -le 1 ] && [ $stop_stage -gt 1 ];then
#=============From timit_prepare_dict====================
#Who knows
srcdir=data
dir=data/local/dict
lmdir=data/local/nist_lm
tmpdir=data/local/lm_tmp

mkdir -p $dir $lmdir $tmpdir

# (2) Create the phone bigram LM
if [ -z $IRSTLM ] ; then
  export IRSTLM=$KALDI_ROOT/tools/irstlm/
fi
export PATH=${PATH}:$IRSTLM/bin
if ! command -v prune-lm >/dev/null 2>&1 ; then
  echo "$0: Error: the IRSTLM is not available or compiled" >&2
  echo "$0: Error: We used to install it by default, but." >&2
  echo "$0: Error: this is no longer the case." >&2
  echo "$0: Error: To install it, go to $KALDI_ROOT/tools" >&2
  echo "$0: Error: and run extras/install_irstlm.sh" >&2
  exit 1
fi

cut -d' ' -f2- $srcdir/train/text | sed -e 's:^:<s> :' -e 's:$: </s>:' \
  > $srcdir/lm_train.text

build-lm.sh -i $srcdir/lm_train.text -n 2 \
  -o $tmpdir/lm_phone_bg.ilm.gz

compile-lm $tmpdir/lm_phone_bg.ilm.gz -t=yes /dev/stdout | \
grep -v unk | gzip -c > $lmdir/lm_phone_bg.arpa.gz

echo "Dictionary & language model preparation succeeded"

#Step 3
  utils/prepare_lang.sh --position-dependent-phones false \
   data/local/dict "SIL" data/local/lang_tmp data/lang

# Next, for each type of language model, create the corresponding FST
# and the corresponding lang_test_* directory.


##===============From timit_format_data================
echo Preparing language models for test

srcdir=data
lmdir=data/local/nist_lm
tmpdir=data/local/lm_tmp
lexicon=data/local/dict/lexicon.txt

mkdir -p $tmpdir

for lm_suffix in bg; do
  test=data/lang_test_${lm_suffix}
  mkdir -p $test
  cp -r data/lang/* $test

  gunzip -c $lmdir/lm_phone_${lm_suffix}.arpa.gz | \
    arpa2fst --disambig-symbol=#0 \
             --read-symbol-table=$test/words.txt - $test/G.fst
  fstisstochastic $test/G.fst
 # The output is like:
 # 9.14233e-05 -0.259833
 # we do expect the first of these 2 numbers to be close to zero (the second is
 # nonzero because the backoff weights make the states sum to >1).
 # Because of the <s> fiasco for these particular LMs, the first number is not
 # as close to zero as it could be.

 # Everything below is only for diagnostic.
 # Checking that G has no cycles with empty words on them (e.g. <s>, </s>);
 # this might cause determinization failure of CLG.
 # #0 is treated as an empty word.
  mkdir -p $tmpdir/g
  awk '{if(NF==1){ printf("0 0 %s %s\n", $1,$1); }} END{print "0 0 #0 #0"; print "0";}' \
    < "$lexicon"  >$tmpdir/g/select_empty.fst.txt
  fstcompile --isymbols=$test/words.txt --osymbols=$test/words.txt $tmpdir/g/select_empty.fst.txt | \
   fstarcsort --sort_type=olabel | fstcompose - $test/G.fst > $tmpdir/g/empty_words.fst
  fstinfo $tmpdir/g/empty_words.fst | grep cyclic | grep -w 'y' &&
    echo "Language model has cycles with empty words" && exit 1
  rm -r $tmpdir/g
done
utils/data/fix_data_dir.sh data/train
utils/data/fix_data_dir.sh data/test
utils/validate_lang.pl data/lang_test_bg || exit 1

echo "Succeeded in formatting data."
rm -r $tmpdir

bash utils/fix_data_dir.sh data/train
bash utils/fix_data_dir.sh data/test

echo "DONE!"
fi