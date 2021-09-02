#!/bin/bash

train_dir=data/local/train
dev_dir=data/local/dev
test_dir=data/local/test
IFS=" "
echo "replacing characters with phonemes"
touch failures
for dir in $train_dir $dev_dir  $test_dir; do
  echo "$dir"
  rm -rf $dir/text_temp
  touch $dir/text_temp
  while read p; do
    read -a strarr <<<"$p"
    output="${strarr[0]} "
    for val in "${strarr[@]:1}"; do
      match="$(grep -w "^$val" subset_data/lexicon.txt || echo '$val SPN')"
      if [[ $match == *"SPN"* ]]; then
        echo "$val" >> failures
        # newmatch=""
        # i=1
        # while [ "$i" -lt "${#val}" ]; do
        #   char=$(expr substr "$val" $i 1)
        #   nw="$(grep -w "^$char" data/lexicon.txt || echo '$val SPN')"
        #   nw="$( cut -d ' ' -f 2- <<< "$nw" )"
        #   newmatch="$newmatch $nw"
        #   i=$(($i + 1))
        # done
        # match="${val} "
        # match+="$newmatch"
      fi
      IFS="\n"
      read -a matcharr <<<"$match"
      translation="${matcharr[0]}"
      string="$( cut -d ' ' -f 2- <<< "$translation" )"
      output+=" ${string}"
      IFS=" "
    done
    echo "$output" >> $dir/text_temp
  done <$dir/text
  cp -f $dir/text $dir/text_characters
  cp -f $dir/text_temp $dir/text
  rm -rf $dir/text_temp
done 
echo "done"
