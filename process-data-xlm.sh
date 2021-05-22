
set -e

SRC=de
TGT=hsb
# MONO_PATH=${NMT_DATA_DIR}/xlm_processed/
# SRC_PATH=$MONO_PATH/$SRC
# TGT_PATH=$MONO_PATH/$TGT

# mkdir -p $MONO_PATH
# mkdir -p $SRC_PATH
# mkdir -p $TGT_PATH
# ############ download and tokenize hsb monolingual data ############ 
# wget -c http://www.statmt.org/wmt20/unsup_and_very_low_res/sorbian_institute_monolingual.hsb.gz
# wget -c http://www.statmt.org/wmt20/unsup_and_very_low_res/witaj_monolingual.hsb.gz 
# wget -c http://www.statmt.org/wmt20/unsup_and_very_low_res/web_monolingual.hsb.gz


# for FILENAME in $TGT_PATH/*hsb.gz; do
#   OUTPUT=${FILENAME%.gz}
#   if [ ! -f "$OUTPUT" ] ; then
#     echo "*** Decompressing $FILENAME... ***"
#     gunzip -c $FILENAME > $OUTPUT
#   else
#     echo "*** $OUTPUT already decompressed. ***"
#   fi
# done

# # concatenate all hsb train data
# if ! [[ -f "$TGT_TRAIN" ]]; then
#     echo "*** Getting hsb train... ***"
#     cat $(ls $TGT_PATH/*monolingual.hsb | grep -v gz) > $TGT_TRAIN
# fi

# ############ download and tokenize de monolingual data ############ 





# ############ download and tokenize de-hsb parallel evaluation corpus ############ 
pair=$SRC-$TGT
OUTPATH=${NMT_DATA_DIR}/xlm_processed/$pair/30k  # path where processed files will be stored
FASTBPE=tools/fastBPE/fast  # path to the fastBPE tool

NUM=500000
# create output path
mkdir -p $OUTPATH



# split  into train / valid / test
echo "*** Split into train / valid / test ***"
split_data() {
    get_seeded_random() {
        seed="$1"; openssl enc -aes-256-ctr -pass pass:"$seed" -nosalt </dev/zero 2>/dev/null
    };
    NLINES=`wc -l $1  | awk -F " " '{print $1}'`;
    NTRAIN=$((NLINES - 10000));
    NVAL=$((NTRAIN + 5000));
    shuf --random-source=<(get_seeded_random 42) $1 | head -$NTRAIN             > $2;
    shuf --random-source=<(get_seeded_random 42) $1 | head -$NVAL | tail -5000  > $3;
    shuf --random-source=<(get_seeded_random 42) $1 | tail -5000                > $4;
}


for lg in $(echo $pair | sed -e 's/\-/ /g'); do
  split_data ${NMT_DATA_DIR}/mono/$lg/all.500000.$lg.tok ${NMT_DATA_DIR}/mono/$lg/$lg.train ${NMT_DATA_DIR}/mono/$lg/$lg.valid ${NMT_DATA_DIR}/mono/$lg/$lg.test
  # build the training set for BPE tokenization by grabbing 500k monolingual sents from
  # each language and concatenating them 
  shuf -r -n $NUM ${NMT_DATA_DIR}/mono/$lg/$lg.train >> $OUTPATH/bpe.train
done
# shuf -r -n $NUM ${NMT_DATA_DIR}/mono/hsb/all.500000.hsb.tok >> $OUTPATH/bpe.train

echo "*** Learning BPE codes ***"
# learn bpe codes on the training set (or only use a subset of it)
$FASTBPE learnbpe 30000 $OUTPATH/bpe.train > $OUTPATH/codes

# getting the post-BPE vocabulary?
$FASTBPE applybpe $OUTPATH/tmp $OUTPATH/bpe.train $OUTPATH/codes
$FASTBPE getvocab $OUTPATH/tmp > $OUTPATH/vocab

echo "*** Applying BPE tokenization and binarizing ***"
for lg in $(echo $pair | sed -e 's/\-/ /g'); do
  for split in train valid test; do 
    $FASTBPE applybpe $OUTPATH/$split.$lg ${NMT_DATA_DIR}/mono/$lg/$lg.$split $OUTPATH/codes &
    python preprocess.py $OUTPATH/vocab $OUTPATH/$split.$lg &
  done
done



echo "*** "
