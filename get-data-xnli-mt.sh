# Copyright (c) 2019-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed under the license found in the
# LICENSE file in the root directory of this source tree.
#
# THIS SCRIPT SHOULD PROCESS XNLI GERMAN, MONOLINGUAL SORBIAN, AND SMALL DEV/TEST PARALLEL FOR DE-HSB
#
# Usage: ./get-data-xnli.sh de
#

set -e

lg=$1

# data paths
MAIN_PATH=$XLM_REPO_DIR
OUTPATH=$NMT_DATA_DIR/xnli
XNLI_PATH=$NMT_DATA_DIR/xnli/XNLI-15way
CODES=$MAIN_PATH/codes_xnli_15
VOCAB=$MAIN_PATH/vocab_xnli_15

PROC_PATH=$NMT_DATA_DIR/xnli/processed

# tools paths
TOOLS_PATH=$XLM_REPO_DIR/tools
TOKENIZE=$TOOLS_PATH/tokenize.sh
LOWER_REMOVE_ACCENT=$TOOLS_PATH/lowercase_and_remove_accent.py

# install tools
./install-tools.sh

# create directories
mkdir -p $OUTPATH
mkdir -p $PROC_PATH

# download data
if [ ! -d $OUTPATH/XNLI-15way ]; then
  if [ ! -f $OUTPATH/XNLI-15way.zip ]; then
    wget -c https://dl.fbaipublicfiles.com/XNLI/XNLI-15way.zip -P $OUTPATH
  fi
  unzip $OUTPATH/XNLI-15way.zip -d $OUTPATH
fi
# we've got a .tsv we need to separate into indivual languages, split--> $split_raw, tokenize --> #split_raw.tok, and binarize --> $split.$lg 


# training things
SRC_TRAIN=$PROC_PATH/train_raw.$lg
SRC_TRAIN_TOK=$SRC_TRAIN.tok
SRC_TRAIN_BPE=$PROC_PATH/train.$lg

echo "*** Extracting $lg data from the tsv file ***"
# since I don't know the column number, I can't use awk easily. Installing a specialized package called csvkit to help
if [ ! -f $SRC_TRAIN ]; then
    # csvcut -t -c $lg $XNLI_PATH/xnli.15way.orig.tsv | csvcut -K 1 | csvformat -T | $TOKENIZE $lg | python $LOWER_REMOVE_ACCENT > $XNLI_PATH/$lg.all
    csvcut -t -c $lg $XNLI_PATH/xnli.15way.orig.tsv | csvcut -K 1 | csvformat -T  > $SRC_TRAIN
fi


# split into train / valid / test
# removed a zero from every number bc it's only 10k set total
split_data() {
    get_seeded_random() {
        seed="$1"; openssl enc -aes-256-ctr -pass pass:"$seed" -nosalt </dev/zero 2>/dev/null
    };
    NLINES=`wc -l $1  | awk -F " " '{print $1}'`;

    NTRAIN=$((NLINES - 1000));
    NVAL=$((NTRAIN + 500));
    shuf --random-source=<(get_seeded_random 42) $1 | head -$NTRAIN             > $2;
    shuf --random-source=<(get_seeded_random 42) $1 | head -$NVAL | tail -500  > $3;
    shuf --random-source=<(get_seeded_random 42) $1 | tail -500                > $4;
}


# echo "*** Splitting $lg data into train, valid, and test ***"
# split_data $XNLI_PATH/$lg.all $PROC_PATH/train_raw.$lg $PROC_PATH/valid_raw.$lg $PROC_PATH/test_raw.$lg

# fastBPE
FASTBPE_DIR=$TOOLS_PATH/fastBPE
FASTBPE=$TOOLS_PATH/fastBPE/fast


echo "*** Tokenizing $lg train data ***" 
if ! [[ -f "$SRC_TRAIN_TOK" ]]; then
  eval "cat $SRC_TRAIN | $TOKENIZE $lg | python $LOWER_REMOVE_ACCENT  > $SRC_TRAIN_TOK"
fi 
echo "*** Applying BPE codes to $lg $split ***"
if ! [[ -f "$SRC_TRAIN_BPE" ]]; then
  $FASTBPE applybpe $SRC_TRAIN_BPE $SRC_TRAIN_TOK $CODES
fi


echo "*** Binarizing $lg data ***"
if ! [[ -f "$SRC_TRAIN_BPE.pth" ]]; then
  python preprocess.py $VOCAB $SRC_TRAIN_BPE
fi

echo "$SRC binarized data in: $SRC_TRAIN_BPE.pth"


# copying codes and vocab to be in the right place for a later script
cp $CODES $PROC_PATH/codes
cp $VOCAB $PROC_PATH/vocab.$lg

############# hsb train data NOT PROCESSED, JUST DOWNLOADED ###########
DEV_OUT=$NMT_DATA_DIR/exp/hsb-$lg
mkdir -p $DEV_OUT

cd $DEV_OUT

# training things
TGT_TRAIN=$DEV_OUT/train_raw.hsb
# TGT_TRAIN_TOK=$TGT_TRAIN.tok
# TGT_TRAIN_BPE=$DEV_OUT/train.$lg

wget -c http://www.statmt.org/wmt20/unsup_and_very_low_res/sorbian_institute_monolingual.hsb.gz


for FILENAME in $DEV_OUT/*hsb.gz; do
  OUTPUT=${FILENAME%.gz}
  if [ ! -f "$OUTPUT" ] ; then
    echo "Decompressing $FILENAME..."
    gunzip -c $FILENAME > $OUTPUT
  else
    echo "$OUTPUT already decompressed."
  fi
done

# hsb train data
if ! [[ -f "$TGT_TRAIN" ]]; then
    echo "Getting hsb train..."
    cat $(ls $DEV_OUT/*monolingual.hsb | grep -v gz) > $TGT_TRAIN
fi

############# de-hsb dev/test data ###########

wget -c http://www.statmt.org/wmt20/unsup_and_very_low_res/devtest.tar.gz

# SRC dev things
SRC_VALID=$DEV_OUT/valid_raw.$lg
SRC_VALID_TOK=$SRC_VALID.tok
SRC_VALID_BPE=$DEV_OUT/valid.$lg

# SRC test things
SRC_TEST=$DEV_OUT/test_raw.$lg
SRC_TEST_TOK=$SRC_TEST.tok
SRC_TEST_BPE=$DEV_OUT/test.$lg

# TGT dev things
TGT_VALID=$DEV_OUT/valid_raw.hsb
TGT_VALID_TOK=$TGT_VALID.tok
TGT_VALID_BPE=$DEV_OUT/valid.hsb

# TGT test things
TGT_TEST=$DEV_OUT/test_raw.hsb
TGT_TEST_TOK=$TGT_TEST.tok
TGT_TEST_BPE=$DEV_OUT/test.hsb

for FILENAME in $DEV_OUT/*tar.gz; do
  OUTPUT=${FILENAME%.gz}
  if [ ! -f "$OUTPUT" ] ; then
    echo "Decompressing $FILENAME..."
    tar -xzvf $FILENAME
  else
    echo "$OUTPUT already decompressed."
  fi
done

if ! [[ -f "$SRC_VALID" ]]; then
    echo "Renaming german dev files..."
    cat $(ls $DEV_OUT/*test.hsb-$lg.$lg | grep -v gz) > $SRC_VALID
fi

if ! [[ -f "$SRC_TEST" ]]; then
    echo "Renaming german dev files..."
    cat $(ls $DEV_OUT/devel.hsb-$lg.$lg | grep -v gz) > $SRC_TEST
fi


if ! [[ -f "$TGT_VALID" ]]; then
    echo "Renaming sorbian dev files..."
    cat $(ls $DEV_OUT/*test.hsb-$lg.hsb | grep -v gz) > $TGT_VALID
fi

if ! [[ -f "$TGT_TEST" ]]; then
    echo "Renaming sorbian dev files..."
    cat $(ls $DEV_OUT/devel.hsb-$lg.hsb | grep -v gz) > $TGT_TEST
fi

# tokenizing dev & test
cd $MAIN_PATH
echo "*** Tokenizing $lg valid/test data ***" 
if ! [[ -f "$SRC_VALID_TOK" ]]; then
  eval "cat $SRC_VALID | $TOKENIZE $lg | python $LOWER_REMOVE_ACCENT > $SRC_VALID_TOK"
fi 

if ! [[ -f "$SRC_TEST_TOK" ]]; then
  eval "cat $SRC_TEST | $TOKENIZE $lg | python $LOWER_REMOVE_ACCENT > $SRC_TEST_TOK"
fi 

# echo "*** Tokenizing hsb train/valid/test data ***"
# if ! [[ -f "$TGT_TRAIN_TOK" ]]; then
#   eval "cat $TGT_TRAIN | $TOKENIZE hsb | python $LOWER_REMOVE_ACCENT  > $TGT_TRAIN_TOK"
# fi  

# if ! [[ -f "$TGT_VALID_TOK" ]]; then
#   eval "cat $TGT_VALID | $TOKENIZE hsb | python $LOWER_REMOVE_ACCENT  > $TGT_VALID_TOK"
# fi 

# if ! [[ -f "$TGT_TEST_TOK" ]]; then
#   eval "cat $TGT_TEST | $TOKENIZE hsb | python $LOWER_REMOVE_ACCENT  > $TGT_TEST_TOK"
# fi 

echo "*** Applying BPE codes to $lg valid/test ***"
if ! [[ -f "$SRC_VALID_BPE" ]]; then
  $FASTBPE applybpe $SRC_VALID_BPE $SRC_VALID_TOK $CODES
fi

if ! [[ -f "$SRC_TEST_BPE" ]]; then
  $FASTBPE applybpe $SRC_TEST_BPE $SRC_TEST_TOK $CODES
fi

# echo "*** Applying BPE codes to hsb train/valid/test ***"
# if ! [[ -f "$TGT_TRAIN_BPE" ]]; then
#   $FASTBPE applybpe $TGT_TRAIN_BPE $TGT_TRAIN_TOK $CODES
# fi

# if ! [[ -f "$TGT_VALID_BPE" ]]; then
#   $FASTBPE applybpe $TGT_VALID_BPE $TGT_VALID_TOK $CODES
# fi

# if ! [[ -f "$TGT_TEST_BPE" ]]; then
#   $FASTBPE applybpe $TGT_TEST_BPE $TGT_TEST_TOK $CODES
# fi

echo "*** Binarizing $lg valid/test data ***"
if ! [[ -f "$SRC_VALID_BPE.pth" ]]; then
  python preprocess.py $VOCAB $SRC_VALID_BPE
fi
if ! [[ -f "$SRC_TEST_BPE.pth" ]]; then
  python preprocess.py $VOCAB $SRC_TEST_BPE
fi

# echo "*** Binarizing hsb train/valid/test data ***"
# if ! [[ -f "$TGT_TRAIN_BPE.pth" ]]; then
#   python preprocess.py $VOCAB $TGT_TRAIN_BPE
# fi
# if ! [[ -f "$TGT_VALID_BPE.pth" ]]; then
#   python preprocess.py $VOCAB $TGT_VALID_BPE
# fi
# if ! [[ -f "$TGT_TEST_BPE.pth" ]]; then
#   python preprocess.py $VOCAB $TGT_TEST_BPE
# fi

# TGT_VOCAB=$DEV_OUT/vocab.hsb

# # extract shsb vocabulary
# if ! [[ -f "$TGT_VOCAB" ]]; then
#   echo "Extracting vocabulary..."
#   $FASTBPE getvocab $TGT_TRAIN_BPE > $TGT_VOCAB
# fi
# echo "$TGT vocab in: $TGT_VOCAB"


echo "$SRC valid binarized data in: $SRC_VALID_BPE.pth"
# echo "$TGT valid binarized data in: $TGT_VALID_BPE.pth"
echo "$SRC test binarized data in: $SRC_TEST_BPE.pth"
# echo "$TGT test binarized data in: $TGT_TEST_BPE.pth"