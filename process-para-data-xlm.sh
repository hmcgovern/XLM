
SRC=de
TGT=hsb
pair=$SRC-$TGT
MAIN_PATH=$PWD
OUTPATH=${NMT_DATA_DIR}/xlm_processed/$pair/30k  # path where processed files will be stored
TOOLS_PATH=$MAIN_PATH/tools
FASTBPE=$TOOLS_PATH/fastBPE/fast  # path to the fastBPE tool

N_THREADS=16
# moses
MOSES=$TOOLS_PATH/mosesdecoder
REPLACE_UNICODE_PUNCT=$MOSES/scripts/tokenizer/replace-unicode-punctuation.perl
NORM_PUNC=$MOSES/scripts/tokenizer/normalize-punctuation.perl
REM_NON_PRINT_CHAR=$MOSES/scripts/tokenizer/remove-non-printing-char.perl
TOKENIZER=$MOSES/scripts/tokenizer/tokenizer.perl
INPUT_FROM_SGM=$MOSES/scripts/ems/support/input-from-sgm.perl
# adding this for the xnli_15 pretrained preprocessing
LOWER_REMOVE_ACCENT=$TOOLS_PATH/lowercase_and_remove_accent.py


NUM=500000
# create output path
mkdir -p $OUTPATH

cd $OUTPATH
cd ..

echo "*** Downloading de-hsb parallel evaluation/test data ***"
wget -c http://www.statmt.org/wmt20/unsup_and_very_low_res/devtest.tar.gz
wget -c http://www.statmt.org/wmt20/unsup_and_very_low_res/blindtest_updated.tar.gz 

echo "*** Extracting parallel data ***"
tar -xzvf devtest.tar.gz -C .
tar -xzvf blindtest_updated.tar.gz -C .

PARA_SRC_VALID=devel.hsb-de.de
PARA_TGT_VALID=devel.hsb-de.hsb

PARA_SRC_TEST=blind_test.de-hsb.de 
PARA_TGT_TEST=blind_test.hsb-de.hsb

echo "*** Tokenizing and Preprocessing Data ***"

SRC_PREPROCESSING="$REPLACE_UNICODE_PUNCT | $NORM_PUNC -l $SRC | $REM_NON_PRINT_CHAR | $TOKENIZER -l $SRC -no-escape -threads $N_THREADS | python $LOWER_REMOVE_ACCENT "
TGT_PREPROCESSING="$REPLACE_UNICODE_PUNCT | $NORM_PUNC -l $TGT | $REM_NON_PRINT_CHAR | $TOKENIZER -l $TGT -no-escape -threads $N_THREADS | python $LOWER_REMOVE_ACCENT"

eval "cat $PARA_SRC_VALID | $SRC_PREPROCESSING > $OUTPATH/valid.$pair.$SRC.tok"
eval "cat $PARA_SRC_TEST | $SRC_PREPROCESSING > $OUTPATH/test.$pair.$SRC.tok"

eval "cat $PARA_TGT_VALID | $TGT_PREPROCESSING > $OUTPATH/valid.$pair.$TGT.tok"
eval "cat $PARA_TGT_TEST | $TGT_PREPROCESSING > $OUTPATH/test.$pair.$TGT.tok"


cd $MAIN_PATH
echo "*** Applying BPE tokenization and binarizing ***"
for lg in $(echo $pair | sed -e 's/\-/ /g'); do
  for split in valid test; do 
    $FASTBPE applybpe $OUTPATH/$split.$pair.$lg $OUTPATH/$split.$pair.$lg.tok $OUTPATH/codes &
    python preprocess.py $OUTPATH/vocab $OUTPATH/$split.$pair.$lg &
  done
done
