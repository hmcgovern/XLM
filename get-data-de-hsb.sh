set -e

#
#
# Data preprocessing configuration
#
N_MONO=500000  # number of monolingual sentences for German
# this really should be used, just use existing codes file
N_THREADS=16    # number of threads in data preprocessing
CODES=80000


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


#
# Check parameters
#
if [ "$SRC" == "" ]; then echo "--src not provided"; exit; fi
if [ "$TGT" == "" ]; then echo "--tgt not provided"; exit; fi
if [ "$SRC" != "de" -a "$SRC" != "en" -a "$SRC" != "fr" -a "$SRC" != "ro" -a "$SRC" != "zh" ]; then echo "unknown source language"; exit; fi
if [ "$TGT" != "de" -a "$TGT" != "en" -a "$TGT" != "fr" -a "$TGT" != "ro" -a "$TGT" != "zh" -a "$TGT" != "hsb" ]; then echo "unknown target language"; exit; fi
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
DATA_PATH=$NMT_DATA_DIR/mono/$TGT
PROC_PATH=$NMT_DATA_DIR/exp/de_hsb
MONO_PATH=$NMT_DATA_DIR/mono
PARA_PATH=$NMT_DATA_DIR/para/$SRC-$TGT


# create paths
mkdir -p $TOOLS_PATH
mkdir -p $PROC_PATH

mkdir -p $DATA_PATH
mkdir -p $MONO_PATH
mkdir -p $PARA_PATH
# mkdir -p $PROC_PATH_SRC
# mkdir -p $PROC_PATH_TGT

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

# valid / test file raw data
# unset PARA_SRC_VALID PARA_TGT_VALID PARA_SRC_TEST PARA_TGT_TEST


# install tools
./install-tools.sh
# ${MAIN_PATH}/install-tools.sh

# ###################################################################################################
# #
# # Download monolingual data
# #

cd $MONO_PATH

# if [ "$SRC" == "de" -o "$TGT" == "de" ]; then
#   echo "Downloading German monolingual data ..."
#   mkdir -p $MONO_PATH/de
#   cd $MONO_PATH/de
#   wget -c http://www.statmt.org/wmt14/training-monolingual-news-crawl/news.2007.de.shuffled.gz
#   wget -c http://www.statmt.org/wmt14/training-monolingual-news-crawl/news.2008.de.shuffled.gz
  # wget -c http://www.statmt.org/wmt14/training-monolingual-news-crawl/news.2009.de.shuffled.gz
  # wget -c http://www.statmt.org/wmt14/training-monolingual-news-crawl/news.2010.de.shuffled.gz
  # wget -c http://www.statmt.org/wmt14/training-monolingual-news-crawl/news.2011.de.shuffled.gz
  # wget -c http://www.statmt.org/wmt14/training-monolingual-news-crawl/news.2012.de.shuffled.gz
  # wget -c http://www.statmt.org/wmt14/training-monolingual-news-crawl/news.2013.de.shuffled.gz
  # wget -c http://www.statmt.org/wmt15/training-monolingual-news-crawl-v2/news.2014.de.shuffled.v2.gz
  # wget -c http://data.statmt.org/wmt16/translation-task/news.2015.de.shuffled.gz
  # wget -c http://data.statmt.org/wmt17/translation-task/news.2016.de.shuffled.gz
  # wget -c http://data.statmt.org/wmt18/translation-task/news.2017.de.shuffled.deduped.gz
# fi

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
  wget -c http://www.statmt.org/wmt20/unsup_and_very_low_res/sorbian_institute_monolingual.hsb.gz
  wget -c http://www.statmt.org/wmt20/unsup_and_very_low_res/witaj_monolingual.hsb.gz
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
for FILENAME in $SRC/*.gz $TGT/*.gz; do
  OUTPUT=${FILENAME%.gz}
  if [ ! -f "$OUTPUT" ] ; then
    echo "Decompressing $FILENAME..."
    tar -xzvf $FILENAME > $OUTPUT
  else
    echo "$OUTPUT already decompressed."
  fi
done

SRC_TRAIN_RAW=$PROC_PATH/train_raw.$SRC
SRC_VALID_RAW=$PROC_PATH/valid_raw.$SRC
SRC_TEST_RAW=$PROC_PATH/test_raw.$SRC

if ! [[ -f "$SRC_TRAIN_RAW" ]]; then
    echo "Concatenating $SRC monolingual data..."
    cat $(ls $SRC/news.*$SRC* | grep -v gz | head -n $N_MONO) > $SRC_TRAIN_RAW
fi

if ! [[ -f "$SRC_VALID_RAW" ]]; then
    echo "Renaming sorbian dev files..."
    cat $(ls $PARA_PATH/*test.$TGT-$SRC.$SRC | grep -v gz) > $SRC_VALID_RAW
fi

if ! [[ -f "$SRC_TEST_RAW" ]]; then
    echo "Renaming sorbian dev files..."
    cat $(ls $PARA_PATH/devel.$TGT-$SRC.$SRC | grep -v gz) > $SRC_TEST_RAW
fi

TGT_TRAIN_RAW=$PROC_PATH/train_raw.$TGT
TGT_VALID_RAW=$PROC_PATH/valid_raw.$TGT
TGT_TEST_RAW=$PROC_PATH/test_raw.$TGT

if ! [[ -f "$TGT_TRAIN_RAW" ]]; then
    echo "Concatenating $TGT monolingual data..."
    cat $(ls $TGT/*$TGT* | grep -v gz) > $TGT_TRAIN_RAW
fi


# #
# # Download parallel data (for evaluation only)
# #

cd $PARA_PATH
wget -c http://www.statmt.org/wmt20/unsup_and_very_low_res/devtest.tar.gz

for FILENAME in $PARA_PATH/*.gz; do
  OUTPUT=${FILENAME%.gz}
  if [ ! -f "$OUTPUT" ] ; then
    echo "Decompressing $FILENAME..."
    tar -xzvf $FILENAME
  else
    echo "$OUTPUT already decompressed."
  fi
done

if ! [[ -f "$TGT_VALID_RAW" ]]; then
    echo "Renaming sorbian dev files..."
    cat $(ls $PARA_PATH/*test.$TGT-$SRC.$TGT | grep -v gz) > $TGT_VALID_RAW
fi

if ! [[ -f "$TGT_TEST_RAW" ]]; then
    echo "Renaming sorbian dev files..."
    cat $(ls $PARA_PATH/devel.$TGT-$SRC.$TGT | grep -v gz) > $TGT_TEST_RAW
fi


cd $PROC_PATH

SRC_TRAIN_TOK=$SRC_TRAIN_RAW.tok
SRC_VALID_TOK=$SRC_VALID_RAW.tok
SRC_TEST_TOK=$SRC_TEST_RAW.tok

TGT_TRAIN_TOK=$TGT_TRAIN_RAW.tok
TGT_VALID_TOK=$TGT_VALID_RAW.tok
TGT_TEST_TOK=$TGT_TEST_RAW.tok

SRC_PREPROCESSING="$REPLACE_UNICODE_PUNCT | $NORM_PUNC -l $SRC | $REM_NON_PRINT_CHAR |                                            $TOKENIZER -l $SRC -no-escape -threads $N_THREADS | python $LOWER_REMOVE_ACCENT "
TGT_PREPROCESSING="$REPLACE_UNICODE_PUNCT | $NORM_PUNC -l $TGT | $REM_NON_PRINT_CHAR |                                            $TOKENIZER -l $TGT -no-escape -threads $N_THREADS | python $LOWER_REMOVE_ACCENT"


# tokenize data
for FILENAME in $SRC_TRAIN_TOK $SRC_VALID_TOK $SRC_TEST_TOK; do
  SRC_FILE=${FILENAME%.tok}
  if ! [[ -f $FILENAME ]]; then
    echo "Tokenize $SRC monolingual data..."
    echo $SRC_FILE $FILENAME
    eval "cat $SRC_FILE | $SRC_PREPROCESSING > $FILENAME"
  fi
done

for FILENAME in $TGT_TRAIN_TOK $TGT_VALID_TOK $TGT_TEST_TOK; do
  TGT_FILE=${FILENAME%.tok}
  if ! [[ -f $FILENAME ]]; then
    echo "Tokenize $TGT monolingual data..."
    echo $TGT_FILE $FILENAME
    eval "cat $TGT_FILE | $TGT_PREPROCESSING > $FILENAME"
  fi
done
echo "$SRC monolingual data tokenized in: $SRC_TOK"
echo "$TGT monolingual data tokenized in: $TGT_TOK"

# reload BPE codes
cd $MAIN_PATH
echo "looking for BPE codes in"
echo ${RELOAD_CODES}


# BPE / vocab files
BPE_CODES=$PROC_PATH/codes
SRC_VOCAB=$PROC_PATH/vocab.$SRC
TGT_VOCAB=$PROC_PATH/vocab.$TGT
FULL_VOCAB=$PROC_PATH/vocab

if [ ! -f "$BPE_CODES" ] && [ -f "$RELOAD_CODES" ]; then
  echo "Reloading BPE codes from $RELOAD_CODES ..."
  cp $RELOAD_CODES $BPE_CODES
fi

# train / valid / test monolingual BPE data
SRC_TRAIN_BPE=$PROC_PATH/train.$SRC
TGT_TRAIN_BPE=$PROC_PATH/train.$TGT
SRC_VALID_BPE=$PROC_PATH/valid.$SRC
TGT_VALID_BPE=$PROC_PATH/valid.$TGT
SRC_TEST_BPE=$PROC_PATH/test.$SRC
TGT_TEST_BPE=$PROC_PATH/test.$TGT

# valid / test parallel data
PARA_SRC_VALID=$PARA_PATH/devel.hsb-de.de
PARA_TGT_VALID=$PARA_PATH/devel.hsb-de.hsb
PARA_SRC_TEST=$PARA_PATH/devel_test.hsb-de.de
PARA_TGT_TEST=$PARA_PATH/devel_test.hsb-de.hsb

# valid / test parallel BPE data
PARA_SRC_VALID_BPE=$PROC_PATH/valid.$SRC-$TGT.$SRC
PARA_TGT_VALID_BPE=$PROC_PATH/valid.$SRC-$TGT.$TGT
PARA_SRC_TEST_BPE=$PROC_PATH/test.$SRC-$TGT.$SRC
PARA_TGT_TEST_BPE=$PROC_PATH/test.$SRC-$TGT.$TGT

# apply BPE codes
if ! [[ -f "$SRC_TRAIN_BPE" ]]; then
  echo "Applying $SRC BPE codes..."
  $FASTBPE applybpe $SRC_TRAIN_BPE $SRC_TRAIN_TOK $BPE_CODES
fi
if ! [[ -f "$TGT_TRAIN_BPE" ]]; then
  echo "Applying $TGT BPE codes..."
  $FASTBPE applybpe $TGT_TRAIN_BPE $TGT_TRAIN_TOK $BPE_CODES
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

if [ ! -f "$FULL_VOCAB" ] && [ -f "$RELOAD_VOCAB" ]; then
  echo "Reloading vocabulary from $RELOAD_VOCAB ..."
  cp $RELOAD_VOCAB $FULL_VOCAB
fi

echo "Applying BPE to valid and test files..."
$FASTBPE applybpe $PARA_SRC_VALID_BPE $PARA_SRC_VALID $BPE_CODES $FULL_VOCAB
$FASTBPE applybpe $PARA_TGT_VALID_BPE $PARA_TGT_VALID $BPE_CODES $FULL_VOCAB
$FASTBPE applybpe $PARA_SRC_TEST_BPE  $PARA_SRC_TEST  $BPE_CODES $FULL_VOCAB
$FASTBPE applybpe $PARA_TGT_TEST_BPE  $PARA_TGT_TEST  $BPE_CODES $FULL_VOCAB


# extract full vocabulary
if ! [[ -f "$FULL_VOCAB" ]]; then
  echo "Extracting vocabulary..."
  $FASTBPE getvocab $SRC_TRAIN_BPE $TGT_TRAIN_BPE > $FULL_VOCAB
fi
echo "Full vocab in: $FULL_VOCAB"



# ###################################################################################################


# # concatenate monolingual data files
# if ! [[ -f "$SRC_RAW" ]]; then
#   echo "Concatenating $SRC monolingual data..."
#   cat $(ls $SRC/*$SRC* | grep -v gz) | head -n $N_MONO > $SRC_RAW
# fi
# if ! [[ -f "$TGT_RAW" ]]; then
#   
# fi
# echo "$SRC monolingual data concatenated in: $SRC_RAW"
# echo "$TGT monolingual data concatenated in: $TGT_RAW"

# # # check number of lines
# # if ! [[ "$(wc -l < $SRC_RAW)" -eq "$N_MONO" ]]; then echo "ERROR: Number of lines does not match! Be sure you have $N_MONO sentences in your $SRC monolingual data."; exit; fi
# # if ! [[ "$(wc -l < $TGT_RAW)" -eq "$N_MONO" ]]; then echo "ERROR: Number of lines does not match! Be sure you have $N_MONO sentences in your $TGT monolingual data."; exit; fi



# # tokenize data
# if ! [[ -f "$SRC_TOK" ]]; then
#   echo "Tokenize $SRC monolingual data..."
#   eval "cat $SRC_RAW | $SRC_PREPROCESSING > $SRC_TOK"
# fi

# if ! [[ -f "$TGT_TOK" ]]; then
#   echo "Tokenize $TGT monolingual data..."
#   eval "cat $TGT_RAW | $TGT_PREPROCESSING > $TGT_TOK"
# fi
# echo "$SRC monolingual data tokenized in: $SRC_TOK"
# echo "$TGT monolingual data tokenized in: $TGT_TOK"

# # reload BPE codes
# cd $MAIN_PATH
# echo "looking for BPE codes in"
# echo ${RELOAD_CODES}


# if [ ! -f "$BPE_CODES" ] && [ -f "$RELOAD_CODES" ]; then
#   echo "Reloading BPE codes from $RELOAD_CODES ..."
#   cp $RELOAD_CODES $BPE_CODES
# fi

# # learn BPE codes
# if [ ! -f "$BPE_CODES" ]; then
#   echo "Learning BPE codes..."
#   exit
#   # putting this sanity check in, if it's learning BPE, I don't want it 
#   # $FASTBPE learnbpe $CODES $SRC_TOK $TGT_TOK > $BPE_CODES
# fi
# echo "BPE learned in $BPE_CODES"

# # apply BPE codes
# if ! [[ -f "$SRC_TRAIN_BPE" ]]; then
#   echo "Applying $SRC BPE codes..."
#   $FASTBPE applybpe $SRC_TRAIN_BPE $SRC_TOK $BPE_CODES
# fi
# if ! [[ -f "$TGT_TRAIN_BPE" ]]; then
#   echo "Applying $TGT BPE codes..."
#   $FASTBPE applybpe $TGT_TRAIN_BPE $TGT_TOK $BPE_CODES
# fi
# echo "BPE codes applied to $SRC in: $SRC_TRAIN_BPE"
# echo "BPE codes applied to $TGT in: $TGT_TRAIN_BPE"

# # # extract source and target vocabulary
# # if ! [[ -f "$SRC_VOCAB" && -f "$TGT_VOCAB" ]]; then
# #   echo "Extracting vocabulary..."
# #   $FASTBPE getvocab $SRC_TRAIN_BPE > $SRC_VOCAB
# #   $FASTBPE getvocab $TGT_TRAIN_BPE > $TGT_VOCAB
# # fi
# # echo "$SRC vocab in: $SRC_VOCAB"
# # echo "$TGT vocab in: $TGT_VOCAB"


# # reload full vocabulary
# cd $MAIN_PATH
# if [ ! -f "$FULL_VOCAB" ] && [ -f "$RELOAD_VOCAB" ]; then
#   echo "Reloading vocabulary from $RELOAD_VOCAB ..."
#   cp $RELOAD_VOCAB $FULL_VOCAB
# fi

# # extract full vocabulary
# if ! [[ -f "$FULL_VOCAB" ]]; then
#   echo "Extracting vocabulary..."
#   $FASTBPE getvocab $SRC_TRAIN_BPE $TGT_TRAIN_BPE > $FULL_VOCAB
# fi
# echo "Full vocab in: $FULL_VOCAB"

# # binarize data
# if ! [[ -f "$SRC_TRAIN_BPE.pth" ]]; then
#   echo "Binarizing $SRC data..."
#   $MAIN_PATH/preprocess.py $FULL_VOCAB $SRC_TRAIN_BPE
# fi
# if ! [[ -f "$TGT_TRAIN_BPE.pth" ]]; then
#   echo "Binarizing $TGT data..."
#   $MAIN_PATH/preprocess.py $FULL_VOCAB $TGT_TRAIN_BPE
# fi
# echo "$SRC binarized data in: $SRC_TRAIN_BPE.pth"
# echo "$TGT binarized data in: $TGT_TRAIN_BPE.pth"


# #
# # Download parallel data (for evaluation only)
# #

# cd $PARA_PATH

# echo "Downloading parallel data..."
# wget -c http://data.statmt.org/wmt18/translation-task/dev.tgz

# echo "Downloading de-hsb parallel data..."
# wget -c http://www.statmt.org/devtest.tar.gz

# echo "Extracting parallel data..."
# tar -xzf dev.tgz
# tar -xzvf devtest.tar.gz

# # check valid and test files are here
# if ! [[ -f "$PARA_SRC_VALID.sgm" ]]; then echo "$PARA_SRC_VALID.sgm is not found!"; exit; fi
# if ! [[ -f "$PARA_TGT_VALID.sgm" ]]; then echo "$PARA_TGT_VALID.sgm is not found!"; exit; fi
# if ! [[ -f "$PARA_SRC_TEST.sgm" ]];  then echo "$PARA_SRC_TEST.sgm is not found!";  exit; fi
# if ! [[ -f "$PARA_TGT_TEST.sgm" ]];  then echo "$PARA_TGT_TEST.sgm is not found!";  exit; fi

# echo "Tokenizing valid and test data..."
# eval "$INPUT_FROM_SGM < $PARA_SRC_VALID.sgm | $SRC_PREPROCESSING > $PARA_SRC_VALID"
# eval "$INPUT_FROM_SGM < $PARA_TGT_VALID.sgm | $TGT_PREPROCESSING > $PARA_TGT_VALID"
# eval "$INPUT_FROM_SGM < $PARA_SRC_TEST.sgm  | $SRC_PREPROCESSING > $PARA_SRC_TEST"
# eval "$INPUT_FROM_SGM < $PARA_TGT_TEST.sgm  | $TGT_PREPROCESSING > $PARA_TGT_TEST"

# # echo "Applying BPE to valid and test files..."
# # $FASTBPE applybpe $PARA_SRC_VALID_BPE $PARA_SRC_VALID $BPE_CODES $SRC_VOCAB
# # $FASTBPE applybpe $PARA_TGT_VALID_BPE $PARA_TGT_VALID $BPE_CODES $TGT_VOCAB
# # $FASTBPE applybpe $PARA_SRC_TEST_BPE  $PARA_SRC_TEST  $BPE_CODES $SRC_VOCAB
# # $FASTBPE applybpe $PARA_TGT_TEST_BPE  $PARA_TGT_TEST  $BPE_CODES $TGT_VOCAB

# echo "Applying BPE to valid and test files..."
# $FASTBPE applybpe $PARA_SRC_VALID_BPE $PARA_SRC_VALID $BPE_CODES $FULL_VOCAB
# $FASTBPE applybpe $PARA_TGT_VALID_BPE $PARA_TGT_VALID $BPE_CODES $FULL_VOCAB
# $FASTBPE applybpe $PARA_SRC_TEST_BPE  $PARA_SRC_TEST  $BPE_CODES $FULL_VOCAB
# $FASTBPE applybpe $PARA_TGT_TEST_BPE  $PARA_TGT_TEST  $BPE_CODES $FULL_VOCAB


# echo "Binarizing data..."
# rm -f $PARA_SRC_VALID_BPE.pth $PARA_TGT_VALID_BPE.pth $PARA_SRC_TEST_BPE.pth $PARA_TGT_TEST_BPE.pth
# $MAIN_PATH/preprocess.py $FULL_VOCAB $PARA_SRC_VALID_BPE
# $MAIN_PATH/preprocess.py $FULL_VOCAB $PARA_TGT_VALID_BPE
# $MAIN_PATH/preprocess.py $FULL_VOCAB $PARA_SRC_TEST_BPE
# $MAIN_PATH/preprocess.py $FULL_VOCAB $PARA_TGT_TEST_BPE


# #
# # Link monolingual validation and test data to parallel data
# #
# ln -sf $PARA_SRC_VALID_BPE.pth $SRC_VALID_BPE.pth
# ln -sf $PARA_TGT_VALID_BPE.pth $TGT_VALID_BPE.pth
# ln -sf $PARA_SRC_TEST_BPE.pth  $SRC_TEST_BPE.pth
# ln -sf $PARA_TGT_TEST_BPE.pth  $TGT_TEST_BPE.pth


# #
# # Summary
# #
# echo ""
# echo "===== Data summary"
# echo "Monolingual training data:"
# echo "    $SRC: $SRC_TRAIN_BPE.pth"
# echo "    $TGT: $TGT_TRAIN_BPE.pth"
# echo "Monolingual validation data:"
# echo "    $SRC: $SRC_VALID_BPE.pth"
# echo "    $TGT: $TGT_VALID_BPE.pth"
# echo "Monolingual test data:"
# echo "    $SRC: $SRC_TEST_BPE.pth"
# echo "    $TGT: $TGT_TEST_BPE.pth"
# echo "Parallel validation data:"
# echo "    $SRC: $PARA_SRC_VALID_BPE.pth"
# echo "    $TGT: $PARA_TGT_VALID_BPE.pth"
# echo "Parallel test data:"
# echo "    $SRC: $PARA_SRC_TEST_BPE.pth"
# echo "    $TGT: $PARA_TGT_TEST_BPE.pth"
# echo ""
