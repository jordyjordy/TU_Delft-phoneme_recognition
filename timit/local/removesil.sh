sed -e 's/\<sil\>//g' data/local/data/train.text -i
sed -e 's/\<sil\>//g' data/local/data/dev.text -i
sed -e 's/\<sil\>//g' data/local/data/test.text -i
sed -e 's/\<epi\>//g' data/local/data/train.text -i
sed -e 's/\<epi\>//g' data/local/data/dev.text -i
sed -e 's/\<epi\>//g' data/local/data/test.text -i
sed -e s/\ \ */\ /g data/local/data/train.text -i
sed -e s/\ \ */\ /g data/local/data/dev.text -i
sed -e s/\ \ */\ /g data/local/data/test.text -i