#!/usr/bin/env bash
# modified from https://raw.githubusercontent.com/alexandra-chron/relm_unmt/master/get_data_and_preprocess.sh

# Copyright (c) 2019-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed under the license found in the
# LICENSE file in the root directory of this source tree.
#
set -e

# Data preprocessing configuration

# CODES=16000     # number of BPE codes
N_THREADS=16    # number of threads in data preprocessing

# Read arguments

POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"
case $key in
  --src)
    SRC="$2"; shift 2;;
  --tgt)
    TGT="$2"; shift 2;;
  --bpe)
    CODES="$2"; shift 2;;
  *)
  POSITIONAL+=("$1")
  shift
  ;;
esac
done
set -- "${POSITIONAL[@]}"

# Check parameters
if [ "$SRC" == "" ]; then echo "--src not provided"; exit; fi
if [ "$TGT" == "" ]; then echo "--tgt not provided"; exit; fi
if [ "$SRC" == "$TGT" ]; then echo "source and target cannot be identical"; exit; fi

# Initialize tools and data paths

# main paths
MAIN_PATH=$XLM_REPO_DIR
TOOLS_PATH=$XLM_REPO_DIR/tools
# we really want this to be the nmt_data DANG have to redo the way I do this
DATA_PATH=$MAIN_PATH
# DATA_PATH=$NMT_DATA_DIR/xnli/processed # german train data will be XNLI
# get the first two numbers of CODES and use it to decorate the processed path
let EXT=$CODES/1000
PROC_PATH=$NMT_DATA_DIR/exp/$TGT-"${EXT}k" # this is where we put the hsb data and hsb-de parallel eval data

# create paths
mkdir -p $TOOLS_PATH
mkdir -p $PROC_PATH

# moses
MOSES=$TOOLS_PATH/mosesdecoder
REPLACE_UNICODE_PUNCT=$MOSES/scripts/tokenizer/replace-unicode-punctuation.perl
NORM_PUNC=$MOSES/scripts/tokenizer/normalize-punctuation.perl
REM_NON_PRINT_CHAR=$MOSES/scripts/tokenizer/remove-non-printing-char.perl
TOKENIZER=$MOSES/scripts/tokenizer/tokenizer.perl
INPUT_FROM_SGM=$MOSES/scripts/ems/support/input-from-sgm.perl

# fastBPE
FASTBPE_DIR=$TOOLS_PATH/fastBPE
FASTBPE=$TOOLS_PATH/fastBPE/fast

LOWER_REMOVE_ACCENT=$TOOLS_PATH/lowercase_and_remove_accent.py

# Sennrich's WMT16 scripts for Romanian preprocessing
WMT16_SCRIPTS=$TOOLS_PATH/wmt16-scripts
NORMALIZE_ROMANIAN=$WMT16_SCRIPTS/preprocess/normalise-romanian.py
REMOVE_DIACRITICS=$WMT16_SCRIPTS/preprocess/remove-diacritics.py

# SRC_TRAIN=$DATA_PATH/train_raw.$SRC
# SRC_TRAIN_TOK=$SRC_TRAIN.tok
# SRC_TRAIN_BPE=$PROC_PATH/train.$SRC

# # NOTE: might need to change the PROC_PATH to DATA_PATH here
# SRC_VALID=$PROC_PATH/valid_raw.$SRC
# SRC_VALID_TOK=$SRC_VALID.tok
# SRC_VALID_BPE=$PROC_PATH/valid.$SRC

# SRC_TEST=$PROC_PATH/test_raw.$SRC
# SRC_TEST_TOK=$SRC_TEST.tok
# SRC_TEST_BPE=$PROC_PATH/test.$SRC

# train/ valid/ test target file data
TGT_TRAIN=$PROC_PATH/train_raw.$TGT
TGT_TRAIN_TOK=$TGT_TRAIN.tok
TGT_TRAIN_BPE=$PROC_PATH/train.$TGT

TGT_VALID=$PROC_PATH/valid_raw.$TGT
TGT_VALID_TOK=$TGT_VALID.tok
TGT_VALID_BPE=$PROC_PATH/valid.$TGT

TGT_TEST=$PROC_PATH/test_raw.$TGT
TGT_TEST_TOK=$TGT_TEST.tok
TGT_TEST_BPE=$PROC_PATH/test.$TGT

# BPE / vocab files
BPE_TGT_CODES=$PROC_PATH/codes.$TGT
# BPE_CODES_HMR=$PROC_PATH/codes
BPE_CODES_HMR=$DATA_PATH/codes_xnli_15 # not lang specific bc it's 15 way
SRC_VOCAB=$DATA_PATH/vocab_xnli_15 # not lang specific bc it's 15 way
# SRC_VOCAB=$DATA_PATH/vocab.$SRC
# SRC_VOCAB=$DATA_PATH/vocab
# SRC_VOCAB=$PROC_PATH/vocab.$SRC
TGT_VOCAB=$PROC_PATH/vocab.$TGT

# valid / test parallel BPE data
PARA_SRC_VALID_BPE=$PROC_PATH/valid.$SRC-$TGT.$SRC
PARA_TGT_VALID_BPE=$PROC_PATH/valid.$SRC-$TGT.$TGT
PARA_SRC_TEST_BPE=$PROC_PATH/test.$SRC-$TGT.$SRC
PARA_TGT_TEST_BPE=$PROC_PATH/test.$SRC-$TGT.$TGT

# install tools
#./install-tools.sh (this should have already run in the get_data_mlm_pretraining.sh script

# preprocessing commands - special case for Romanian
if [ "$SRC" == "ro" ]; then
  SRC_PREPROCESSING="$REPLACE_UNICODE_PUNCT | $NORM_PUNC -l $SRC | $REM_NON_PRINT_CHAR | $NORMALIZE_ROMANIAN | $REMOVE_DIACRITICS | $TOKENIZER -l $SRC -no-escape -threads $N_THREADS"
else
  SRC_PREPROCESSING="$REPLACE_UNICODE_PUNCT | $NORM_PUNC -l $SRC | $REM_NON_PRINT_CHAR | python $LOWER_REMOVE_ACCENT |              $TOKENIZER -l $SRC -no-escape -threads $N_THREADS"
fi

if [ "$TGT" == "ro" ]; then
  TGT_PREPROCESSING="$REPLACE_UNICODE_PUNCT | $NORM_PUNC -l $TGT | $REM_NON_PRINT_CHAR | $NORMALIZE_ROMANIAN | $REMOVE_DIACRITICS | $TOKENIZER -l $TGT -no-escape -threads $N_THREADS"
else
  TGT_PREPROCESSING="$REPLACE_UNICODE_PUNCT | $NORM_PUNC -l $TGT | $REM_NON_PRINT_CHAR | $TOKENIZER -l $TGT -no-escape -threads $N_THREADS"
fi

# tokenize data
if ! [[ -f "$TGT_TRAIN_TOK" ]]; then
  echo "*** Tokenize $TGT monolingual data... ***"
  eval "cat $TGT_TRAIN | $TGT_PREPROCESSING | python $LOWER_REMOVE_ACCENT > $TGT_TRAIN_TOK"
fi

echo "*** $TGT monolingual data tokenized in: $TGT_TRAIN_TOK ***"

# learn BPE codes on the hsb data

if [ ! -f "$BPE_TGT_CODES" ]; then
  echo "*** Learning BPE codes... ***"
  $FASTBPE learnbpe $CODES $TGT_TRAIN_TOK > $BPE_TGT_CODES
fi
echo "*** $TGT BPE learned in $BPE_TGT_CODES ***"

BPE_JOINT_CODES=$PROC_PATH/codes.full


python join_codes.py --codes_path $PROC_PATH --final_codes_path $BPE_JOINT_CODES --top_k 80000


# learn BPE codes on the concatenation of the SRC and TGT datasets
# this is only the de-hsb data, we want it 
# if [ ! -f "$BPE_JOINT_CODES" ]; then
#   echo "Learning BPE codes..."
#   $FASTBPE learnbpe $CODES $SRC_TRAIN_TOK $TGT_TRAIN_TOK > $BPE_JOINT_CODES
# fi
# echo "BPE learned in $BPE_JOINT_CODES"

# apply BPE codes
if ! [[ -f "$TGT_TRAIN_BPE" ]]; then
  echo "*** Applying joint BPE codes to $TGT... ***"
  $FASTBPE applybpe $TGT_TRAIN_BPE $TGT_TRAIN_TOK $BPE_JOINT_CODES #$BPE_CODES_HMR
  # $FASTBPE applybpe $TGT_TRAIN_BPE $TGT_TRAIN_TOK $BPE_JOINT_CODES
fi

echo "*** BPE from $BPE_JOINT_CODES codes applied to $TGT in: $TGT_TRAIN_BPE ***"

# extract target (hsb) vocabulary
if ! [[ -f "$TGT_VOCAB" ]]; then
  echo "*** Extracting vocabulary... ***"
  $FASTBPE getvocab $TGT_TRAIN_BPE > $TGT_VOCAB
fi
echo "$TGT vocab in: $TGT_VOCAB"

# compute full vocabulary
echo "*** Extracting vocabulary... *** "
LANGSVOCAB=$(python $MAIN_PATH/add_vocabs.py $SRC $TGT $DATA_PATH/ $PROC_PATH/)
VOCAB=$(echo $LANGSVOCAB | cut -d " " -f 3)

VOCAB_FINAL=$PROC_PATH/$VOCAB
echo "*** Full vocab in: $VOCAB_FINAL ***"

# # binarize data
# if ! [[ -f "$SRC_TRAIN_BPE.pth" ]]; then
#   echo "*** Binarizing $SRC data... ***"
#   $MAIN_PATH/preprocess.py $VOCAB_FINAL $SRC_TRAIN_BPE
# fi

# echo "*** $SRC binarized data in: $SRC_TRAIN_BPE.pth ***"

if ! [[ -f "$TGT_TRAIN_BPE.pth" ]]; then
  echo "*** Binarizing $TGT data... ***"
  $MAIN_PATH/preprocess.py $VOCAB_FINAL $TGT_TRAIN_BPE
fi

echo "*** $TGT binarized data in: $TGT_TRAIN_BPE.pth ***"

echo "*** Tokenizing valid and test data... ***"

# tokenize data
# if ! [[ -f "$SRC_VALID_TOK" ]]; then
#   eval "cat $SRC_VALID | $SRC_PREPROCESSING | python $LOWER_REMOVE_ACCENT > $SRC_VALID_TOK"
# fi
# if ! [[ -f "$SRC_TEST_TOK" ]]; then
#   eval "cat $SRC_TEST | $SRC_PREPROCESSING| python $LOWER_REMOVE_ACCENT > $SRC_TEST_TOK"
# fi

if ! [[ -f "$TGT_VALID_TOK" ]]; then
  eval "cat $TGT_VALID | $TGT_PREPROCESSING | python $LOWER_REMOVE_ACCENT > $TGT_VALID_TOK"
fi

if ! [[ -f "$TGT_TEST_TOK" ]]; then
  eval "cat $TGT_TEST | $TGT_PREPROCESSING | python $LOWER_REMOVE_ACCENT > $TGT_TEST_TOK"
fi

echo "*** Applying BPE to valid and test files... ***"

# $FASTBPE applybpe $SRC_VALID_BPE "$SRC_VALID_TOK" $BPE_CODES_HMR
# $FASTBPE applybpe $SRC_TEST_BPE  "$SRC_TEST_TOK"  $BPE_CODES_HMR

$FASTBPE applybpe $TGT_VALID_BPE "$TGT_VALID_TOK" $BPE_JOINT_CODES
$FASTBPE applybpe $TGT_TEST_BPE  "$TGT_TEST_TOK"  $BPE_JOINT_CODES
# $FASTBPE applybpe $TGT_VALID_BPE "$TGT_VALID_TOK" $BPE_TGT_CODES
# $FASTBPE applybpe $TGT_TEST_BPE  "$TGT_TEST_TOK"  $BPE_TGT_CODES

echo "*** Binarizing data... ***"
# rm -f  $SRC_VALID_BPE.pth $SRC_TEST_BPE.pth
rm -f  $TGT_VALID_BPE.pth $TGT_TEST_BPE.pth

# $MAIN_PATH/preprocess.py $VOCAB_FINAL $SRC_VALID_BPE
# $MAIN_PATH/preprocess.py $VOCAB_FINAL $SRC_TEST_BPE

$MAIN_PATH/preprocess.py $VOCAB_FINAL $TGT_VALID_BPE
$MAIN_PATH/preprocess.py $VOCAB_FINAL $TGT_TEST_BPE

#
# Link monolingual validation and test data to parallel data, also link SRC train set to this folder
#
# ln $SRC_VALID_BPE.pth $PARA_SRC_VALID_BPE.pth
# ln $TGT_VALID_BPE.pth $PARA_TGT_VALID_BPE.pth
# ln $SRC_TEST_BPE.pth $PARA_SRC_TEST_BPE.pth
ln $TGT_TEST_BPE.pth $PARA_TGT_TEST_BPE.pth

# Summary

echo ""
echo "===== Data summary"
echo "Monolingual training data:"
echo "    $SRC: $PROC_PATH/train.$SRC.pth"
echo "    $TGT: $TGT_TRAIN_BPE.pth"
echo "Monolingual validation data:"
echo "    $SRC: $PROC_PATH/valid.$SRC.pth"
echo "    $TGT: $TGT_VALID_BPE.pth"
echo "Monolingual test data:"
echo "    $SRC: $PROC_PATH/test.$SRC.pth"
echo "    $TGT: $TGT_TEST_BPE.pth"
echo "Parallel validation data:"
echo "    $SRC: $PARA_SRC_VALID_BPE.pth"
echo "    $TGT: $PARA_TGT_VALID_BPE.pth"
echo "Parallel test data:"
echo "    $SRC: $PARA_SRC_TEST_BPE.pth"
echo "    $TGT: $PARA_TGT_TEST_BPE.pth"
echo ""