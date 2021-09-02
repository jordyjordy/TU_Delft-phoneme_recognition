#!/bin/bash

dir=data/local/dict
input=$dir/lexicon.txt
tempfile=data/local/dict/tempphon
rm -rf data/local/dict/tempphon
rm -rf data/local/dict/tempphon2
rm -rf data/local/dict/tempphon3
touch data/local/dict/tempphon
while read p; do
    read -a matcharr<<<"$p"
    for phon in "${matcharr[@]:1}"; do
        echo "$phon" >> data/local/dict/tempphon
    done
done <$input
sort data/local/dict/tempphon > data/local/dict/tempphon2
uniq data/local/dict/tempphon2 > data/local/dict/nonsilence_phones.txt
rm -rf data/local/dict/tempphon
rm -rf data/local/dict/tempphon2