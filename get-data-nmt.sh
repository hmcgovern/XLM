# Copyright (c) 2019-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed under the license found in the
# LICENSE file in the root directory of this source tree.
#

set -e


#
# Data preprocessing configuration
#
N_MONO=700000  # number of monolingual sentences for each language
N_THREADS=16    # number of threads in data preprocessing


#
# Read arguments
#
POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"
case $key in
  --src)
    SRC="$2"; shift 2;;
  --tgt)
    TGT="$2"; shift 2;;
  --reload_codes)
    RELOAD_CODES="$2"; shift 2;;
  --reload_vocab)
    RELOAD_VOCAB="$2"; shift 2;;
  *)
  POSITIONAL+=("$1")
  shift
  ;;
esac
done
set -- "${POSITIONAL[@]}"


# switch order of src and tgt if necessary
# SRC=$(echo $pair | cut -f1 -d-)
# TGT=$(echo $pair | cut -f2 -d-)
# if they're in the wrong order, switch them
if [ "$SRC" \> "$TGT" ]; then
  tmp1=$SRC #de
  tmp2=$TGT #bg
  SRC=$tmp2 
  TGT=$tmp1
fi

#
# Check parameters
#
if [ "$SRC" == "" ]; then echo "--src not provided"; exit; fi
if [ "$TGT" == "" ]; then echo "--tgt not provided"; exit; fi
# if [ "$SRC" != "de" -a "$SRC" != "en" -a "$SRC" != "fr" -a "$SRC" != "ro" -a "$SRC" != "zh" -a "$SRC" != "bg" -a "$SRC" != "ru" -a "$SRC" != "ar" ]; then echo "unknown source language"; exit; fi
# if [ "$TGT" != "de" -a "$TGT" != "en" -a "$TGT" != "fr" -a "$TGT" != "ro" -a "$TGT" != "zh" -a "$TGT" != "hsb" -a "$TGT" != "bg" -a "$TGT" != "ru" -a "$TGT" != "ar" ]; then echo "unknown target language"; exit; fi
if [ "$SRC" == "$TGT" ]; then echo "source and target cannot be identical"; exit; fi
if [ "$SRC" \> "$TGT" ]; then echo "please ensure SRC < TGT"; exit; fi
if [ "$RELOAD_CODES" != "" ] && [ ! -f "$RELOAD_CODES" ]; then echo "cannot locate BPE codes"; exit; fi
if [ "$RELOAD_VOCAB" != "" ] && [ ! -f "$RELOAD_VOCAB" ]; then echo "cannot locate vocabulary"; exit; fi
if [ "$RELOAD_CODES" == "" -a "$RELOAD_VOCAB" != "" -o "$RELOAD_CODES" != "" -a "$RELOAD_VOCAB" == "" ]; then echo "BPE codes should be provided if and only if vocabulary is also provided"; exit; fi


#
# Initialize tools and data paths
#

# main paths
MAIN_PATH=$PWD
TOOLS_PATH=/$PWD/tools
DATA_PATH=${NMT_DATA_DIR}
MONO_PATH=$DATA_PATH/mono
PARA_PATH=$DATA_PATH/para
PROC_PATH=$DATA_PATH/processed/$SRC-$TGT
#TODO: have two diff proc path, one for source, one for target
PROC_PATH_SRC=$DATA_PATH/processed/$SRC
PROC_PATH_TGT=$DATA_PATH/processed/$TGT

PARA_OUT=$PARA_PATH/$SRC-$TGT

# create paths
mkdir -p $TOOLS_PATH
mkdir -p $DATA_PATH
mkdir -p $MONO_PATH
mkdir -p $PARA_PATH
mkdir -p $PROC_PATH
mkdir -p $PROC_PATH_SRC
mkdir -p $PROC_PATH_TGT
mkdir -p $PARA_OUT

# moses
MOSES=$TOOLS_PATH/mosesdecoder
REPLACE_UNICODE_PUNCT=$MOSES/scripts/tokenizer/replace-unicode-punctuation.perl
NORM_PUNC=$MOSES/scripts/tokenizer/normalize-punctuation.perl
REM_NON_PRINT_CHAR=$MOSES/scripts/tokenizer/remove-non-printing-char.perl
TOKENIZER=$MOSES/scripts/tokenizer/tokenizer.perl
INPUT_FROM_SGM=$MOSES/scripts/ems/support/input-from-sgm.perl
# adding this for the xnli_15 pretrained preprocessing
LOWER_REMOVE_ACCENT=$TOOLS_PATH/lowercase_and_remove_accent.py

# fastBPE
FASTBPE_DIR=$TOOLS_PATH/fastBPE
FASTBPE=$TOOLS_PATH/fastBPE/fast

# Sennrich's WMT16 scripts for Romanian preprocessing
WMT16_SCRIPTS=$TOOLS_PATH/wmt16-scripts
NORMALIZE_ROMANIAN=$WMT16_SCRIPTS/preprocess/normalise-romanian.py
REMOVE_DIACRITICS=$WMT16_SCRIPTS/preprocess/remove-diacritics.py

# raw and tokenized files
SRC_RAW=$MONO_PATH/$SRC/all.$N_MONO.$SRC
TGT_RAW=$MONO_PATH/$TGT/all.$N_MONO.$TGT
SRC_TOK=$SRC_RAW.tok
TGT_TOK=$TGT_RAW.tok

# BPE / vocab files
BPE_CODES=$PROC_PATH/codes
SRC_VOCAB=$PROC_PATH/vocab.$SRC
TGT_VOCAB=$PROC_PATH/vocab.$TGT
FULL_VOCAB=$PROC_PATH/vocab
# FULL_VOCAB=$PROC_PATH/vocab.$SRC-$TGT


# train / valid / test monolingual BPE data
SRC_TRAIN_BPE=$PROC_PATH_SRC/train.$SRC
TGT_TRAIN_BPE=$PROC_PATH_TGT/train.$TGT
SRC_VALID_BPE=$PROC_PATH_SRC/valid.$SRC
TGT_VALID_BPE=$PROC_PATH_TGT/valid.$TGT
SRC_TEST_BPE=$PROC_PATH_SRC/test.$SRC
TGT_TEST_BPE=$PROC_PATH_TGT/test.$TGT

# valid / test parallel BPE data
PARA_SRC_VALID_BPE=$PROC_PATH/valid.$SRC-$TGT.$SRC
PARA_TGT_VALID_BPE=$PROC_PATH/valid.$SRC-$TGT.$TGT
PARA_SRC_TEST_BPE=$PROC_PATH/test.$SRC-$TGT.$SRC
PARA_TGT_TEST_BPE=$PROC_PATH/test.$SRC-$TGT.$TGT

# valid / test file raw data
unset PARA_SRC_VALID PARA_TGT_VALID PARA_SRC_TEST PARA_TGT_TEST
if [ "$SRC" == "en" -a "$TGT" == "fr" ]; then
  PARA_SRC_VALID=$PARA_PATH/dev/newstest2013-ref.en
  PARA_TGT_VALID=$PARA_PATH/dev/newstest2013-ref.fr
  PARA_SRC_TEST=$PARA_PATH/dev/newstest2014-fren-ref.en
  PARA_TGT_TEST=$PARA_PATH/dev/newstest2014-fren-ref.fr
fi
if [ "$SRC" == "de" -a "$TGT" == "en" ]; then
  PARA_SRC_VALID=$PARA_PATH/dev/newstest2013-ref.de
  PARA_TGT_VALID=$PARA_PATH/dev/newstest2013-ref.en
  PARA_SRC_TEST=$PARA_PATH/dev/newstest2016-ende-ref.de
  PARA_TGT_TEST=$PARA_PATH/dev/newstest2016-deen-ref.en
fi
if [ "$SRC" == "en" -a "$TGT" == "ro" ]; then
  PARA_SRC_VALID=$PARA_PATH/dev/newsdev2016-roen-ref.en
  PARA_TGT_VALID=$PARA_PATH/dev/newsdev2016-enro-ref.ro
  PARA_SRC_TEST=$PARA_PATH/dev/newstest2016-roen-ref.en
  PARA_TGT_TEST=$PARA_PATH/dev/newstest2016-enro-ref.ro
fi
if [ "$SRC" == "en" -a "$TGT" == "zh" ]; then
  PARA_SRC_VALID=$PARA_PATH/dev/newsdev2017-zhen-ref.en
  PARA_TGT_VALID=$PARA_PATH/dev/newsdev2017-enzh-ref.zh
  PARA_SRC_TEST=$PARA_PATH/dev/newstest2017-zhen-ref.en
  PARA_TGT_TEST=$PARA_PATH/dev/newstest2017-enzh-ref.zh
fi

if [ "$SRC" == "en" -a "$TGT" == "ru" ]; then
  PARA_SRC_VALID=$PARA_PATH/dev/newsdev2017-zhen-ref.en
  PARA_TGT_VALID=$PARA_PATH/dev/newsdev2017-enzh-ref.zh
  PARA_SRC_TEST=$PARA_PATH/dev/newstest2017-zhen-ref.en
  PARA_TGT_TEST=$PARA_PATH/dev/newstest2017-enzh-ref.zh
fi

########## de/hsb development valid/test ##########
if [ "$SRC" == "de" -a "$TGT" == "hsb" ]; then
  PARA_SRC_VALID=$PARA_PATH/de-hsb/devel.hsb-de.de
  PARA_TGT_VALID=$PARA_PATH/de-hsb/devel.hsb-de.hsb
  # NOTE: above two are from development set, bottom two are from blindtest set. Not good practice but oh well.
  # NOTE: this was a lie from the pit of HELL. They are not parallel to each other so of NO use as a blind test set
  # PARA_SRC_TEST=$PARA_PATH/de-hsb/blind_test.de-hsb.de
  # PARA_TGT_TEST=$PARA_PATH/de-hsb/blind_test.hsb-de.hsb
  PARA_SRC_TEST=$PARA_PATH/de-hsb/devel_test.hsb-de.de
  PARA_TGT_TEST=$PARA_PATH/de-hsb/devel_test.hsb-de.hsb
fi 
# install tools
./install-tools.sh
# ${MAIN_PATH}/install-tools.sh


if [ "$SRC" == "de" -a "$TGT" == "bg" ]; then
  PARA_SRC_VALID=$PARA_PATH/bg-de/valid.de-bg.de
  PARA_TGT_VALID=$PARA_PATH/bg-de/valid.de-bg.bg
  PARA_SRC_TEST=$PARA_PATH/bg-de/test.de-bg.de
  PARA_TGT_TEST=$PARA_PATH/bg-de/test.de-bg.bg
fi

if [ "$SRC" == "de" -a "$TGT" == "ru" ]; then
  PARA_SRC_VALID=$PARA_PATH/de-ru/valid.de-ru.de
  PARA_TGT_VALID=$PARA_PATH/de-ru/valid.de-ru.ru
  PARA_SRC_TEST=$PARA_PATH/de-ru/test.de-ru.de
  PARA_TGT_TEST=$PARA_PATH/de-ru/test.de-ru.ru
fi

if [ "$SRC" == "de" -a "$TGT" == "ar" ]; then
  PARA_SRC_VALID=$PARA_PATH/ar-de/valid.ar-de.de
  PARA_TGT_VALID=$PARA_PATH/ar-de/valid.ar-de.ar
  PARA_SRC_TEST=$PARA_PATH/ar-de/test.ar-de.de
  PARA_TGT_TEST=$PARA_PATH/ar-de/test.ar-de.ar
fi

if [ "$SRC" == "de" -a "$TGT" == "fr" ]; then
  PARA_SRC_VALID=$PARA_PATH/de-fr/valid.de-fr.de
  PARA_TGT_VALID=$PARA_PATH/de-fr/valid.de-fr.fr
  PARA_SRC_TEST=$PARA_PATH/de-fr/test.de-fr.de
  PARA_TGT_TEST=$PARA_PATH/de-fr/test.de-fr.fr
fi

# ###################################################################################################
# #
# # Download monolingual data
# #

cd $MONO_PATH

if [ "$SRC" == "de" -o "$TGT" == "de" ]; then
  echo "Downloading German monolingual data ..."
  mkdir -p $MONO_PATH/de
  cd $MONO_PATH/de
  # wget -c http://www.statmt.org/wmt14/training-monolingual-news-crawl/news.2007.de.shuffled.gz
  # wget -c http://www.statmt.org/wmt14/training-monolingual-news-crawl/news.2008.de.shuffled.gz
  # wget -c http://www.statmt.org/wmt14/training-monolingual-news-crawl/news.2009.de.shuffled.gz
  # wget -c http://www.statmt.org/wmt14/training-monolingual-news-crawl/news.2010.de.shuffled.gz
  # wget -c http://www.statmt.org/wmt14/training-monolingual-news-crawl/news.2011.de.shuffled.gz
  # wget -c http://www.statmt.org/wmt14/training-monolingual-news-crawl/news.2012.de.shuffled.gz
  # wget -c http://www.statmt.org/wmt14/training-monolingual-news-crawl/news.2013.de.shuffled.gz
  # wget -c http://www.statmt.org/wmt15/training-monolingual-news-crawl-v2/news.2014.de.shuffled.v2.gz
  wget -c http://data.statmt.org/wmt16/translation-task/news.2015.de.shuffled.gz
  wget -c http://data.statmt.org/wmt17/translation-task/news.2016.de.shuffled.gz
  # wget -c http://data.statmt.org/wmt18/translation-task/news.2017.de.shuffled.deduped.gz
fi

if [ "$SRC" == "en" -o "$TGT" == "en" ]; then
  echo "Downloading English monolingual data ..."
  mkdir -p $MONO_PATH/en
  cd $MONO_PATH/en
  wget -c http://www.statmt.org/wmt14/training-monolingual-news-crawl/news.2007.en.shuffled.gz
  # wget -c http://www.statmt.org/wmt14/training-monolingual-news-crawl/news.2008.en.shuffled.gz
  # wget -c http://www.statmt.org/wmt14/training-monolingual-news-crawl/news.2009.en.shuffled.gz
  # wget -c http://www.statmt.org/wmt14/training-monolingual-news-crawl/news.2010.en.shuffled.gz
  # wget -c http://www.statmt.org/wmt14/training-monolingual-news-crawl/news.2011.en.shuffled.gz
  # wget -c http://www.statmt.org/wmt14/training-monolingual-news-crawl/news.2012.en.shuffled.gz
  # wget -c http://www.statmt.org/wmt14/training-monolingual-news-crawl/news.2013.en.shuffled.gz
  # wget -c http://www.statmt.org/wmt15/training-monolingual-news-crawl-v2/news.2014.en.shuffled.v2.gz
  # wget -c http://data.statmt.org/wmt16/translation-task/news.2015.en.shuffled.gz
  # wget -c http://data.statmt.org/wmt17/translation-task/news.2016.en.shuffled.gz
  # wget -c http://data.statmt.org/wmt18/translation-task/news.2017.en.shuffled.deduped.gz
fi

if [ "$SRC" == "fr" -o "$TGT" == "fr" ]; then
  echo "Downloading French monolingual data ..."
  mkdir -p $MONO_PATH/fr
  cd $MONO_PATH/fr
  wget -c http://www.statmt.org/wmt14/training-monolingual-news-crawl/news.2007.fr.shuffled.gz
  wget -c http://www.statmt.org/wmt14/training-monolingual-news-crawl/news.2008.fr.shuffled.gz
  # wget -c http://www.statmt.org/wmt14/training-monolingual-news-crawl/news.2009.fr.shuffled.gz
  # wget -c http://www.statmt.org/wmt14/training-monolingual-news-crawl/news.2010.fr.shuffled.gz
  # wget -c http://www.statmt.org/wmt14/training-monolingual-news-crawl/news.2011.fr.shuffled.gz
  # wget -c http://www.statmt.org/wmt14/training-monolingual-news-crawl/news.2012.fr.shuffled.gz
  # wget -c http://www.statmt.org/wmt14/training-monolingual-news-crawl/news.2013.fr.shuffled.gz
  # wget -c http://www.statmt.org/wmt15/training-monolingual-news-crawl-v2/news.2014.fr.shuffled.v2.gz
  # wget -c http://data.statmt.org/wmt17/translation-task/news.2015.fr.shuffled.gz
  # wget -c http://data.statmt.org/wmt17/translation-task/news.2016.fr.shuffled.gz
  # wget -c http://data.statmt.org/wmt17/translation-task/news.2017.fr.shuffled.gz
fi


if [ "$SRC" == "zh" -o "$TGT" == "zh" ]; then
  echo "Downloading Chinese monolingual data ..."
  mkdir -p $MONO_PATH/zh
  cd $MONO_PATH/zh

  wget -c http://data.statmt.org/news-crawl/zh/news.2008.zh.shuffled.deduped.gz 
  wget -c http://data.statmt.org/news-crawl/zh/news.2010.zh.shuffled.deduped.gz 
  # wget -c http://data.statmt.org/news-crawl/zh/news.2011.zh.shuffled.deduped.gz 
  # wget -c http://data.statmt.org/news-crawl/zh/news.2012.zh.shuffled.deduped.gz	 
  # wget -c http://data.statmt.org/news-crawl/zh/news.2013.zh.shuffled.deduped.gz 
  # wget -c http://data.statmt.org/news-crawl/zh/news.2014.zh.shuffled.deduped.gz 
  # wget -c http://data.statmt.org/news-crawl/zh/news.2015.zh.shuffled.deduped.gz
  # wget -c http://data.statmt.org/news-crawl/zh/news.2016.zh.shuffled.deduped.gz	 
  # wget -c http://data.statmt.org/news-crawl/zh/news.2017.zh.shuffled.deduped.gz	 
  # wget -c http://data.statmt.org/news-crawl/zh/news.2018.zh.shuffled.deduped.gz
  # wget -c http://data.statmt.org/news-crawl/zh/news.2019.zh.shuffled.deduped.gz	 
  # wget -c http://data.statmt.org/news-crawl/zh/news.2020.zh.shuffled.deduped.gz	

fi

if [ "$SRC" == "hsb" -o "$TGT" == "hsb" ]; then
  echo "Downloading Upper Sorbian monolingual data ..."
  mkdir -p $MONO_PATH/hsb
  cd $MONO_PATH/hsb

  # get all the WMT data
  # NOTE: I rename it, just so all the downstream functionality can run smoothly and I don't have to hack it. 
  wget -c http://www.statmt.org/wmt20/unsup_and_very_low_res/sorbian_institute_monolingual.hsb.gz -O news.sorbian_institute_monolingual.hsb.gz
  wget -c http://www.statmt.org/wmt20/unsup_and_very_low_res/witaj_monolingual.hsb.gz -O news.witaj_monolingual.hsb.gz
  wget -c http://www.statmt.org/wmt20/unsup_and_very_low_res/web_monolingual.hsb.gz -O news.web_monolingual.hsb.gz
  wget -c http://www.statmt.org/wmt20/unsup_and_very_low_res/train.hsb-de.hsb.gz -O news.train.hsb.gz
fi


if [ "$SRC" == "ro" -o "$TGT" == "ro" ]; then
  echo "Downloading Romanian monolingual data ..."
  mkdir -p $MONO_PATH/ro
  cd $MONO_PATH/ro
  wget -c http://data.statmt.org/wmt16/translation-task/news.2015.ro.shuffled.gz
fi


if [ "$SRC" == "bg" -o "$TGT" == "bg" ]; then
  echo "Downloading Bulgarian monolingual data ..."
  mkdir -p $MONO_PATH/bg
  cd $MONO_PATH/bg

  # wget -c http://data.statmt.org/news-crawl/bg/news.2013.bg.shuffled.deduped.gz
  # wget -c http://data.statmt.org/news-crawl/bg/news.2014.bg.shuffled.deduped.gz	
  # wget -c http://data.statmt.org/news-crawl/bg/news.2015.bg.shuffled.deduped.gz	
  # wget -c http://data.statmt.org/news-crawl/bg/news.2016.bg.shuffled.deduped.gz
  # wget -c http://data.statmt.org/news-crawl/bg/news.2017.bg.shuffled.deduped.gz
  wget -c http://data.statmt.org/news-crawl/bg/news.2018.bg.shuffled.deduped.gz
  wget -c http://data.statmt.org/news-crawl/bg/news.2019.bg.shuffled.deduped.gz
  # wget -c http://data.statmt.org/news-crawl/bg/news.2020.bg.shuffled.deduped.gz

fi


if [ "$SRC" == "ru" -o "$TGT" == "ru" ]; then
  echo "Downloading Russian monolingual data ..."
  mkdir -p $MONO_PATH/ru
  cd $MONO_PATH/ru

  # wget -c http://data.statmt.org/news-crawl/ru/news.2008.ru.shuffled.deduped.gz
  # wget -c http://data.statmt.org/news-crawl/ru/news.2009.ru.shuffled.deduped.gz
  # wget -c http://data.statmt.org/news-crawl/ru/news.2010.ru.shuffled.deduped.gz
  # wget -c http://data.statmt.org/news-crawl/ru/news.2011.ru.shuffled.deduped.gz
  # wget -c http://data.statmt.org/news-crawl/ru/news.2012.ru.shuffled.deduped.gz
  # wget -c http://data.statmt.org/news-crawl/ru/news.2013.ru.shuffled.deduped.gz
  # wget -c http://data.statmt.org/news-crawl/ru/news.2014.ru.shuffled.deduped.gz
  # wget -c http://data.statmt.org/news-crawl/ru/news.2015.ru.shuffled.deduped.gz
  # wget -c http://data.statmt.org/news-crawl/ru/news.2016.ru.shuffled.deduped.gz
  # wget -c http://data.statmt.org/news-crawl/ru/news.2017.ru.shuffled.deduped.gz
  wget -c http://data.statmt.org/news-crawl/ru/news.2018.ru.shuffled.deduped.gz
  wget -c http://data.statmt.org/news-crawl/ru/news.2019.ru.shuffled.deduped.gz
  # wget -c http://data.statmt.org/news-crawl/ru/news.2020.ru.shuffled.deduped.gz

fi

if [ "$SRC" == "ar" -o "$TGT" == "ar" ]; then
  echo "Downloading Arabic monolingual data ..."
  mkdir -p $MONO_PATH/ar
  cd $MONO_PATH/ar

  wget -c http://data.statmt.org/news-crawl/ar/news.2020.ar.shuffled.deduped.gz	

fi


if [ "$SRC" == "hi" -o "$TGT" == "hi" ]; then
  echo "Downloading Hindi monolingual data ..."
  mkdir -p $MONO_PATH/hi
  cd $MONO_PATH/hi

  wget -c http://www.statmt.org/wmt14/training-monolingual-news-crawl/news.2008.hi.shuffled.gz
  wget -c http://www.statmt.org/wmt14/training-monolingual-news-crawl/news.2009.hi.shuffled.gz

fi


cd $MONO_PATH

# # decompress monolingual data
# for FILENAME in $SRC/news*gz $TGT/news*gz; do
#   OUTPUT=${FILENAME::-3}
#   if [ ! -f "$OUTPUT" ] ; then
#     echo "Decompressing $FILENAME..."
#     gunzip -c $FILENAME > $OUTPUT
#   else
#     echo "$OUTPUT already decompressed."
#   fi
# done

# decompress monolingual data
for FILENAME in $SRC/news* $TGT/news*; do
  OUTPUT=${FILENAME%.gz}
  if [ ! -f "$OUTPUT" ] ; then
    echo "Decompressing $FILENAME..."
    gunzip -c $FILENAME > $OUTPUT
  else
    echo "$OUTPUT already decompressed."
  fi
done


####################################################################################################


# concatenate monolingual data files
if ! [[ -f "$SRC_RAW" ]]; then
  echo "Concatenating $SRC monolingual data..."
  cat $(ls $SRC/news*$SRC* | grep -v gz) | head -n $N_MONO > $SRC_RAW
fi
if ! [[ -f "$TGT_RAW" ]]; then
  echo "Concatenating $TGT monolingual data..."
  cat $(ls $TGT/news*$TGT* | grep -v gz) | head -n $N_MONO > $TGT_RAW
fi
echo "$SRC monolingual data concatenated in: $SRC_RAW"
echo "$TGT monolingual data concatenated in: $TGT_RAW"

# # check number of lines
if ! [[ "$(wc -l < $SRC_RAW)" -eq "$N_MONO" ]]; then echo "ERROR: Number of lines does not match! Be sure you have $N_MONO sentences in your $SRC monolingual data."; exit; fi
if ! [[ "$(wc -l < $TGT_RAW)" -eq "$N_MONO" ]]; then echo "ERROR: Number of lines does not match! Be sure you have $N_MONO sentences in your $TGT monolingual data."; exit; fi

# preprocessing commands - special case for Romanian
if [ "$SRC" == "ro" ]; then
  SRC_PREPROCESSING="$REPLACE_UNICODE_PUNCT | $NORM_PUNC -l $SRC | $REM_NON_PRINT_CHAR | $NORMALIZE_ROMANIAN | $REMOVE_DIACRITICS | $TOKENIZER -l $SRC -no-escape -threads $N_THREADS"
else
  SRC_PREPROCESSING="$REPLACE_UNICODE_PUNCT | $NORM_PUNC -l $SRC | $REM_NON_PRINT_CHAR |                                            $TOKENIZER -l $SRC -no-escape -threads $N_THREADS | python $LOWER_REMOVE_ACCENT "
# else
#   SRC_PREPROCESSING="$REPLACE_UNICODE_PUNCT | $NORM_PUNC -l $SRC | $REM_NON_PRINT_CHAR |                                            $TOKENIZER -l $SRC -no-escape -threads $N_THREADS"
fi
if [ "$TGT" == "ro" ]; then
  TGT_PREPROCESSING="$REPLACE_UNICODE_PUNCT | $NORM_PUNC -l $TGT | $REM_NON_PRINT_CHAR | $NORMALIZE_ROMANIAN | $REMOVE_DIACRITICS | $TOKENIZER -l $TGT -no-escape -threads $N_THREADS"
else
  TGT_PREPROCESSING="$REPLACE_UNICODE_PUNCT | $NORM_PUNC -l $TGT | $REM_NON_PRINT_CHAR |                                            $TOKENIZER -l $TGT -no-escape -threads $N_THREADS | python $LOWER_REMOVE_ACCENT"
# else
#   TGT_PREPROCESSING="$REPLACE_UNICODE_PUNCT | $NORM_PUNC -l $TGT | $REM_NON_PRINT_CHAR |                                            $TOKENIZER -l $TGT -no-escape -threads $N_THREADS"
fi

# tokenize data
if ! [[ -f "$SRC_TOK" ]]; then
  echo "Tokenize $SRC monolingual data..."
  eval "cat $SRC_RAW | $SRC_PREPROCESSING > $SRC_TOK"
fi

if ! [[ -f "$TGT_TOK" ]]; then
  echo "Tokenize $TGT monolingual data..."
  eval "cat $TGT_RAW | $TGT_PREPROCESSING > $TGT_TOK"
fi
echo "$SRC monolingual data tokenized in: ${SRC_TOK}"
echo "$TGT monolingual data tokenized in: ${TGT_TOK}"

# reload BPE codes
cd $MAIN_PATH
echo "looking for BPE codes in"
echo ${RELOAD_CODES}


if [ ! -f "$BPE_CODES" ] && [ -f "$RELOAD_CODES" ]; then
  echo "Reloading BPE codes from $RELOAD_CODES ..."
  cp $RELOAD_CODES $BPE_CODES
fi


# learn BPE codes
if [ ! -f "$BPE_CODES" ]; then
  echo "Learning BPE codes..."
  exit
  # putting this sanity check in, if it's learning BPE, I don't want it 
  # $FASTBPE learnbpe $CODES $SRC_TOK $TGT_TOK > $BPE_CODES
fi
echo "BPE learned in $BPE_CODES"

# apply BPE codes
if ! [[ -f "$SRC_TRAIN_BPE" ]]; then
  echo "Applying $SRC BPE codes..."
  $FASTBPE applybpe $SRC_TRAIN_BPE $SRC_TOK $BPE_CODES
fi
if ! [[ -f "$TGT_TRAIN_BPE" ]]; then
  echo "Applying $TGT BPE codes..."
  $FASTBPE applybpe $TGT_TRAIN_BPE $TGT_TOK $BPE_CODES

fi
echo "BPE codes applied to $SRC in: $SRC_TRAIN_BPE"
echo "BPE codes applied to $TGT in: $TGT_TRAIN_BPE"

# extract source and target vocabulary
if ! [[ -f "$SRC_VOCAB" && -f "$TGT_VOCAB" ]]; then
  echo "Extracting vocabulary..."
  $FASTBPE getvocab $SRC_TRAIN_BPE > $SRC_VOCAB
  $FASTBPE getvocab $TGT_TRAIN_BPE > $TGT_VOCAB
fi
echo "$SRC vocab in: $SRC_VOCAB"
echo "$TGT vocab in: $TGT_VOCAB"


# reload full vocabulary
cd $MAIN_PATH
if [ ! -f "$FULL_VOCAB" ] && [ -f "$RELOAD_VOCAB" ]; then
  echo "Reloading vocabulary from $RELOAD_VOCAB ..."
  cp $RELOAD_VOCAB $FULL_VOCAB
fi

# extract full vocabulary
if ! [[ -f "$FULL_VOCAB" ]]; then
  echo "Extracting vocabulary..."
  $FASTBPE getvocab $SRC_TRAIN_BPE $TGT_TRAIN_BPE > $FULL_VOCAB
fi
echo "Full vocab in: $FULL_VOCAB"

# binarize data
if ! [[ -f "$SRC_TRAIN_BPE.pth" ]]; then
  echo "Binarizing $SRC data..."
  $MAIN_PATH/preprocess.py $FULL_VOCAB $SRC_TRAIN_BPE
fi
if ! [[ -f "$TGT_TRAIN_BPE.pth" ]]; then
  echo "Binarizing $TGT data..."
  $MAIN_PATH/preprocess.py $FULL_VOCAB $TGT_TRAIN_BPE
fi
echo "$SRC binarized data in: $SRC_TRAIN_BPE.pth"
echo "$TGT binarized data in: $TGT_TRAIN_BPE.pth"


# if [ "$SRC" == "de" ] && [ ! "$TGT" == "hsb" ]; then
#  # we just gon symlink the valid and test to the ones in de-$TGT folder and exit the file. good thinking

#   #
#   # Link monolingual validation and test data to parallel data
#   #
#   ln -sf $PARA_SRC_VALID_BPE.pth $SRC_VALID_BPE.pth
#   ln -sf $PARA_TGT_VALID_BPE.pth $TGT_VALID_BPE.pth
#   ln -sf $PARA_SRC_TEST_BPE.pth  $SRC_TEST_BPE.pth
#   ln -sf $PARA_TGT_TEST_BPE.pth  $TGT_TEST_BPE.pth

#   #
#   # Summary
#   #
#   echo ""
#   echo "===== Data summary"
#   echo "Monolingual training data:"
#   echo "    $SRC: $SRC_TRAIN_BPE.pth"
#   echo "    $TGT: $TGT_TRAIN_BPE.pth"
#   echo "Monolingual validation data:"
#   echo "    $SRC: $SRC_VALID_BPE.pth"
#   echo "    $TGT: $TGT_VALID_BPE.pth"
#   echo "Monolingual test data:"
#   echo "    $SRC: $SRC_TEST_BPE.pth"
#   echo "    $TGT: $TGT_TEST_BPE.pth"
#   echo "Parallel validation data:"
#   echo "    $SRC: $PARA_SRC_VALID_BPE.pth"
#   echo "    $TGT: $PARA_TGT_VALID_BPE.pth"
#   echo "Parallel test data:"
#   echo "    $SRC: $PARA_SRC_TEST_BPE.pth"
#   echo "    $TGT: $PARA_TGT_TEST_BPE.pth"
#   echo ""

#   exit


# fi

#
# Download parallel data (for evaluation only)
#

cd $PARA_PATH

echo "Downloading parallel data..."
wget -c http://data.statmt.org/wmt18/translation-task/dev.tgz

echo "Downloading de-hsb parallel data..."
wget -c http://www.statmt.org/wmt20/unsup_and_very_low_res/devtest.tar.gz
wget -c http://www.statmt.org/wmt20/unsup_and_very_low_res/blindtest_updated.tar.gz 


echo "*** Extracting parallel data ***"
tar -xzf dev.tgz
tar -xzvf devtest.tar.gz -C $PARA_OUT
tar -xzvf blindtest_updated.tar.gz -C $PARA_OUT

# # tokenize, BPE, and binarize yourself bc it's not working the other way with the .sgm files
if [ "$SRC" == "de" ] && [ "$TGT" == "hsb" ]; then

  # tokenize data
  if ! [[ -f "$PARA_SRC_VALID.tok" ]] || [[ -f "$PARA_SRC_TEST.tok" ]]; then
    echo "Tokenize $SRC valid/test data..."
    eval "cat $PARA_SRC_VALID | $SRC_PREPROCESSING > $PARA_SRC_VALID.tok"
    eval "cat $PARA_SRC_TEST | $SRC_PREPROCESSING > $PARA_SRC_TEST.tok"
  fi

  if ! [[ -f "$PARA_TGT_VALID.tok" ]] || [[ -f "$PARA_TGT_TEST.tok" ]]; then
    echo "Tokenize $TGT valid/test data..."
    eval "cat $PARA_TGT_VALID | $TGT_PREPROCESSING > $PARA_TGT_VALID.tok"
    eval "cat $PARA_TGT_TEST | $TGT_PREPROCESSING > $PARA_TGT_TEST.tok"
  fi

  echo "$SRC valid/blindtest data tokenized in: $SRC_VALID_TOK $SRC_TEST_TOK"
  echo "$TGT valid/blindtest data tokenized in: $TGT_VALID_TOK $TGT_TEST_TOK"


  # apply BPE codes
  if ! [[ -f "$PARA_SRC_VALID_BPE" ]] || [[ -f "$PARA_SRC_TEST_BPE" ]]; then
    echo "Applying $SRC BPE codes..."
    # NOTE: $SRC and $TGT vocabs were not here originally
    $FASTBPE applybpe $PARA_SRC_VALID_BPE $PARA_SRC_VALID.tok $BPE_CODES $SRC_VOCAB
    $FASTBPE applybpe $PARA_SRC_TEST_BPE $PARA_SRC_TEST.tok $BPE_CODES $SRC_VOCAB
  fi
  if ! [[ -f "$PARA_TGT_VALID_BPE" ]] || [[ -f "$PARA_TGT_TEST_BPE" ]]; then
    echo "Applying $TGT BPE codes..."
    $FASTBPE applybpe $PARA_TGT_VALID_BPE $PARA_TGT_VALID.tok $BPE_CODES $TGT_VOCAB
    $FASTBPE applybpe $PARA_TGT_TEST_BPE $PARA_TGT_TEST.tok $BPE_CODES $TGT_VOCAB

  fi

  echo "BPE codes applied to $SRC in: $PARA_SRC_VALID_BPE $PARA_SRC_TEST_BPE"
  echo "BPE codes applied to $TGT in: $PARA_TGT_VALID_BPE $PARA_TGT_TEST_BPE"

else
  # check valid and test files are here
  if ! [[ -f "$PARA_SRC_VALID.sgm" ]]; then echo "$PARA_SRC_VALID.sgm is not found!"; exit; fi
  if ! [[ -f "$PARA_TGT_VALID.sgm" ]]; then echo "$PARA_TGT_VALID.sgm is not found!"; exit; fi
  if ! [[ -f "$PARA_SRC_TEST.sgm" ]];  then echo "$PARA_SRC_TEST.sgm is not found!";  exit; fi
  if ! [[ -f "$PARA_TGT_TEST.sgm" ]];  then echo "$PARA_TGT_TEST.sgm is not found!";  exit; fi

  echo "*** Tokenizing valid and test data ***"
  eval "$INPUT_FROM_SGM < $PARA_SRC_VALID.sgm | $SRC_PREPROCESSING > $PARA_SRC_VALID"
  eval "$INPUT_FROM_SGM < $PARA_TGT_VALID.sgm | $TGT_PREPROCESSING > $PARA_TGT_VALID"
  eval "$INPUT_FROM_SGM < $PARA_SRC_TEST.sgm  | $SRC_PREPROCESSING > $PARA_SRC_TEST"
  eval "$INPUT_FROM_SGM < $PARA_TGT_TEST.sgm  | $TGT_PREPROCESSING > $PARA_TGT_TEST"

  echo "Applying BPE to valid and test files..."
  $FASTBPE applybpe $PARA_SRC_VALID_BPE $PARA_SRC_VALID $BPE_CODES $SRC_VOCAB
  $FASTBPE applybpe $PARA_TGT_VALID_BPE $PARA_TGT_VALID $BPE_CODES $TGT_VOCAB
  $FASTBPE applybpe $PARA_SRC_TEST_BPE  $PARA_SRC_TEST  $BPE_CODES $SRC_VOCAB
  $FASTBPE applybpe $PARA_TGT_TEST_BPE  $PARA_TGT_TEST  $BPE_CODES $TGT_VOCAB

  # echo "*** Applying BPE to valid and test files ***"
  # $FASTBPE applybpe $PARA_SRC_VALID_BPE $PARA_SRC_VALID $BPE_CODES $FULL_VOCAB
  # $FASTBPE applybpe $PARA_TGT_VALID_BPE $PARA_TGT_VALID $BPE_CODES $FULL_VOCAB
  # $FASTBPE applybpe $PARA_SRC_TEST_BPE  $PARA_SRC_TEST  $BPE_CODES $FULL_VOCAB
  # $FASTBPE applybpe $PARA_TGT_TEST_BPE  $PARA_TGT_TEST  $BPE_CODES $FULL_VOCAB
fi

echo "*** Binarizing data ***"
rm -f $PARA_SRC_VALID_BPE.pth $PARA_TGT_VALID_BPE.pth $PARA_SRC_TEST_BPE.pth $PARA_TGT_TEST_BPE.pth
$MAIN_PATH/preprocess.py $FULL_VOCAB $PARA_SRC_VALID_BPE
$MAIN_PATH/preprocess.py $FULL_VOCAB $PARA_TGT_VALID_BPE
$MAIN_PATH/preprocess.py $FULL_VOCAB $PARA_SRC_TEST_BPE
$MAIN_PATH/preprocess.py $FULL_VOCAB $PARA_TGT_TEST_BPE


#
# Link monolingual validation and test data to parallel data
#
ln -sf $PARA_SRC_VALID_BPE.pth $SRC_VALID_BPE.pth
ln -sf $PARA_TGT_VALID_BPE.pth $TGT_VALID_BPE.pth
ln -sf $PARA_SRC_TEST_BPE.pth  $SRC_TEST_BPE.pth
ln -sf $PARA_TGT_TEST_BPE.pth  $TGT_TEST_BPE.pth


#
# Summary
#
echo ""
echo "===== Data summary"
echo "Monolingual training data:"
echo "    $SRC: $SRC_TRAIN_BPE.pth"
echo "    $TGT: $TGT_TRAIN_BPE.pth"
echo "Monolingual validation data:"
echo "    $SRC: $SRC_VALID_BPE.pth"
echo "    $TGT: $TGT_VALID_BPE.pth"
echo "Monolingual test data:"
echo "    $SRC: $SRC_TEST_BPE.pth"
echo "    $TGT: $TGT_TEST_BPE.pth"
echo "Parallel validation data:"
echo "    $SRC: $PARA_SRC_VALID_BPE.pth"
echo "    $TGT: $PARA_TGT_VALID_BPE.pth"
echo "Parallel test data:"
echo "    $SRC: $PARA_SRC_TEST_BPE.pth"
echo "    $TGT: $PARA_TGT_TEST_BPE.pth"
echo ""


