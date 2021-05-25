
set -e

SRC=de
TGT=hsb
SRC_MONO_PATH=${NMT_DATA_DIR}/mono/$SRC
TGT_MONO_PATH=${NMT_DATA_DIR}/mono/$TGT

TOKENIZE=${XLM_REPO_DIR}/tools/tokenize.sh
# SRC_PATH=$MONO_PATH/$SRC
# TGT_PATH=$MONO_PATH/$TGT

# mkdir -p $MONO_PATH
# mkdir -p $SRC_PATH
# mkdir -p $TGT_PATH

# ############ download and tokenize hsb monolingual data ############ 
cd $TGT_MONO_PATH
wget -c http://www.statmt.org/wmt20/unsup_and_very_low_res/sorbian_institute_monolingual.hsb.gz -O news.sorbian_institute_monolingual.hsb.gz
wget -c http://www.statmt.org/wmt20/unsup_and_very_low_res/witaj_monolingual.hsb.gz -O news.witaj_monolingual.hsb.gz
wget -c http://www.statmt.org/wmt20/unsup_and_very_low_res/web_monolingual.hsb.gz -O news.web_monolingual.hsb.gz
wget -c http://www.statmt.org/wmt20/unsup_and_very_low_res/train.hsb-de.hsb.gz -O news.train.hsb.gz


for FILENAME in $TGT_MONO_PATH/*$TGT.gz; do
  OUTPUT=${FILENAME%.gz}
  if [ ! -f "$OUTPUT" ] ; then
    echo "*** Decompressing $FILENAME... ***"
    gunzip -c $FILENAME > $OUTPUT
  else
    echo "*** $OUTPUT already decompressed. ***"
  fi
done

# concatenate all hsb train data
if ! [[ -f "all.$TGT" ]]; then
    echo "*** Getting all hsb data ... ***"
    cat $(ls $TGT_MONO_PATH/news*.hsb | grep -v gz) > all.$TGT
fi


# tokenize 
if ! [[ -f "all.$TGT.tok" ]]; then
    echo "*** Tokenizing hsb data ... ***"
    eval "cat all.$TGT | $TOKENIZE $TGT > all.$TGT.tok"
fi
# exit

# ############ download and tokenize de monolingual data ############ 
cd $SRC_MONO_PATH

for FILENAME in $SRC_MONO_PATH/*$SRC*.gz; do
  OUTPUT=${FILENAME%.gz}
  if [ ! -f "$OUTPUT" ] ; then
    echo "*** Decompressing $FILENAME... ***"
    gunzip -c $FILENAME > $OUTPUT
  else
    echo "*** $OUTPUT already decompressed. ***"
  fi
done

# concatenate all de data
if ! [[ -f "all.$SRC" ]]; then
    echo "*** Getting all de data ... ***"
    cat $(ls $SRC_MONO_PATH/news*.$SRC.shuffled | grep -v gz ) | head -n 1000000 > all.$SRC
fi


# tokenize 
if ! [[ -f "all.$SRC.tok" ]]; then
    echo "*** Tokenizing de data ... ***"
    eval "cat all.$SRC | $TOKENIZE $SRC > all.$SRC.tok"
fi

# for FILE in ${SRC_MONO_PATH}/all.$SRC ${TGT_MONO_PATH}/all.$TGT; do
#   wc -w $FILE >> ${NMT_DATA_DIR}/xlm_processed/de-hsb/30k_mixed/lg2count.txt 
# done

# exit


# ############ download and tokenize de-hsb parallel evaluation corpus ############ 
pair=$SRC-$TGT
OUTPATH=${NMT_DATA_DIR}/xlm_processed/$pair/30k_mixed  # path where processed files will be stored
FASTBPE=${XLM_REPO_DIR}/tools/fastBPE/fast  # path to the fastBPE tool


# create output path
mkdir -p $OUTPATH


# make lg2count.txt


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


# we split the data, then subsample the data to get bpe.train
for lg in $(echo $pair | sed -e 's/\-/ /g'); do
  split_data ${NMT_DATA_DIR}/mono/$lg/all.$lg.tok ${NMT_DATA_DIR}/mono/$lg/$lg.train ${NMT_DATA_DIR}/mono/$lg/$lg.valid ${NMT_DATA_DIR}/mono/$lg/$lg.test
  # build the training set for BPE tokenization by grabbing 500k monolingual sents from
  # each language and concatenating them 
  
  # shuf -r -n $NUM ${NMT_DATA_DIR}/mono/$lg/$lg.train >> $OUTPATH/bpe.train
done
# shuf -r -n $NUM ${NMT_DATA_DIR}/mono/hsb/all.500000.hsb.tok >> $OUTPATH/bpe.train
cd $OUTPATH

# python ${XLM_REPO_DIR}/get_bpe_train_ranking.py --S 0.5 --scale 10 --lgs "de-hsb"

# cd $MAIN_PATH
# echo "*** Learning BPE codes ***"
# # learn bpe codes on the training set (or only use a subset of it)
# $FASTBPE learnbpe 60000 $OUTPATH/bpe.train.factor=0.5 > $OUTPATH/codes

# getting the post-BPE vocabulary?
# $FASTBPE applybpe $OUTPATH/tmp $OUTPATH/bpe.train.factor=0.5 $OUTPATH/codes
# $FASTBPE getvocab $OUTPATH/tmp > $OUTPATH/vocab

echo "*** Applying BPE tokenization and binarizing ***"
for lg in $(echo $pair | sed -e 's/\-/ /g'); do
  for split in train valid test; do 
    # $FASTBPE applybpe $OUTPATH/$split.$lg ${NMT_DATA_DIR}/mono/$lg/$lg.$split $OUTPATH/codes &
    python ${XLM_REPO_DIR}/preprocess.py $OUTPATH/vocab $OUTPATH/$split.$lg &
  done
done




