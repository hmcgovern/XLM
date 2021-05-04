#!/usr/bin/env bash
# Copyright (c) 2019-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed under the license found in the
# LICENSE file in the root directory of this source tree.
#

#
# Usage: ./get-data-para.sh $lg_pair
#

set -e

# pair=$1  # input language pair
# RELOAD_CODES=$2
# RELOAD_VOCAB=$3


# these are values for splitting that will be overwritten for smaller datasets aka xnli
NTRAIN_SUB=10000
NVAL_SUB=5000


#
# Read arguments
#
POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"
case $key in
  --pair)
    pair="$2"; shift 2;;
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

echo $pair $RELOAD_CODES $RELOAD_VOCAB

SRC=$(echo $pair | cut -f1 -d-)
TGT=$(echo $pair | cut -f2 -d-)
# if they're in the wrong order, switch them
if [ "$SRC" \> "$TGT" ]; then
  pair=$TGT-$SRC
fi

#
# Check parameters
#

if [ "$RELOAD_CODES" != "" ] && [ ! -f "$RELOAD_CODES" ]; then echo "cannot locate BPE codes"; exit; fi
if [ "$RELOAD_VOCAB" != "" ] && [ ! -f "$RELOAD_VOCAB" ]; then echo "cannot locate vocabulary"; exit; fi
if [ "$RELOAD_CODES" == "" -a "$RELOAD_VOCAB" != "" -o "$RELOAD_CODES" != "" -a "$RELOAD_VOCAB" == "" ]; then echo "BPE codes should be provided if and only if vocabulary is also provided"; exit; fi


# data paths
MAIN_PATH=$PWD
PARA_PATH=${NMT_DATA_DIR}/para/$pair
OUTPATH=${NMT_DATA_DIR}/processed/$pair

# tools paths
TOOLS_PATH=$PWD/tools
TOKENIZE=$TOOLS_PATH/tokenize.sh
LOWER_REMOVE_ACCENT=$TOOLS_PATH/lowercase_and_remove_accent.py

# install tools
./install-tools.sh

# create directories
mkdir -p $PARA_PATH
mkdir -p $OUTPATH


#
# Download and uncompress data
#

# ar-en
if [ $pair == "ar-en" ]; then
  # OpenSubtitles 2018
  # wget -c http://opus.nlpl.eu/download.php?f=OpenSubtitles2018%2Far-en.txt.zip -P $PARA_PATH
  # MultiUN
  wget -c http://opus.nlpl.eu/download.php?f=MultiUN%2Far-en.txt.zip -P $PARA_PATH
  unzip -u $PARA_PATH/download.php?f=MultiUN%2Far-en.txt.zip -d $PARA_PATH
fi

# bg-en
if [ $pair == "bg-en" ]; then
  # OpenSubtitles 2018
  # wget -c http://opus.nlpl.eu/download.php?f=OpenSubtitles2018%2Fbg-en.txt.zip -P $PARA_PATH
  # EU Bookshop
  wget -c http://opus.nlpl.eu/download.php?f=EUbookshop%2Fbg-en.txt.zip -P $PARA_PATH
  unzip -u $PARA_PATH/download.php?f=EUbookshop%2Fbg-en.txt.zip -d $PARA_PATH
  # Europarl
  wget -c http://opus.nlpl.eu/download.php?f=Europarl%2Fbg-en.txt.zip -P $PARA_PATH
  unzip -u $PARA_PATH/download.php?f=Europarl%2Fbg-en.txt.zip -d $PARA_PATH
fi

# de-en
if [ $pair == "de-en" ]; then
  # OpenSubtitles 2018
  # wget -c http://opus.nlpl.eu/download.php?f=OpenSubtitles2018%2Fde-en.txt.zip -P $PARA_PATH
  # EU Bookshop
  wget -c http://opus.nlpl.eu/download.php?f=EUbookshop%2Fde-en.txt.zip -P $PARA_PATH
  unzip -u $PARA_PATH/download.php?f=EUbookshop%2Fde-en.txt.zip -d $PARA_PATH
fi

# el-en
if [ $pair == "el-en" ]; then
  # OpenSubtitles 2018
  # wget -c http://opus.nlpl.eu/download.php?f=OpenSubtitles2018%2Fel-en.txt.zip -P $PARA_PATH
  # EU Bookshop
  wget -c http://opus.nlpl.eu/download.php?f=EUbookshop%2Fel-en.txt.zip -P $PARA_PATH
  unzip -u $PARA_PATH/download.php?f=EUbookshop%2Fel-en.txt.zip -d $PARA_PATH
fi

# en-es
if [ $pair == "en-es" ]; then
  # OpenSubtitles 2018
  # wget -c http://opus.nlpl.eu/download.php?f=OpenSubtitles2018%2Fen-es.txt.zip -P $PARA_PATH
  # EU Bookshop
  # wget -c http://opus.nlpl.eu/download.php?f=EUbookshop%2Fen-es.txt.zip -P $PARA_PATH
  # MultiUN
  wget -c https://object.pouta.csc.fi/OPUS-MultiUN/v1/moses/en-es.txt.zip -P $PARA_PATH
  unzip -u $PARA_PATH/en-es.txt.zip -d $PARA_PATH
fi

# en-fr
if [ $pair == "en-fr" ]; then
  echo "Download parallel data for English-French"
  # OpenSubtitles 2018
  wget -c http://opus.nlpl.eu/download.php?f=OpenSubtitles2018%2Fen-fr.txt.zip -P $PARA_PATH
  unzip -u $PARA_PATH/download.php?f=OpenSubtitles2018%2Fen-fr.txt.zip -d $PARA_PATH
  # EU Bookshop
  # wget -c http://opus.nlpl.eu/download.php?f=EUbookshop%2Fen-fr.txt.zip -P $PARA_PATH
  # MultiUN
  # wget -c https://object.pouta.csc.fi/OPUS-MultiUN/v1/moses/en-fr.txt.zip -P $PARA_PATH
  # unzip -u $PARA_PATH/en-fr.txt.zip -d $PARA_PATH
fi

# en-hi
if [ $pair == "en-hi" ]; then
  echo "Download parallel data for English-Hindi"
  # IIT Bombay English-Hindi Parallel Corpus
  wget -c http://www.cfilt.iitb.ac.in/iitb_parallel/iitb_corpus_download/parallel.tgz -P $PARA_PATH
  tar -xvf $PARA_PATH/parallel.tgz -d $PARA_PATH
fi

# en-ru
if [ $pair == "en-ru" ]; then
  echo "Download parallel data for English-Russian"
  # OpenSubtitles 2018
  # wget -c http://opus.nlpl.eu/download.php?f=OpenSubtitles2018%2Fen-ru.txt.zip -P $PARA_PATH
  # MultiUN
  wget -c http://opus.nlpl.eu/download.php?f=MultiUN%2Fen-ru.txt.zip -P $PARA_PATH
  unzip -u download.php?f=MultiUN%2Fen-ru.txt.zip -d $PARA_PATH
fi

# en-sw
if [ $pair == "en-sw" ]; then
  echo "Download parallel data for English-Swahili"
  # Tanzil
  wget -c http://opus.nlpl.eu/download.php?f=Tanzil%2Fen-sw.txt.zip -P $PARA_PATH
  unzip -u download.php?f=Tanzil%2Fen-sw.txt.zip -d $PARA_PATH
  # GlobalVoices
  wget -c http://opus.nlpl.eu/download.php?f=GlobalVoices%2Fen-sw.txt.zip -P $PARA_PATH
  unzip -u download.php?f=GlobalVoices%2Fen-sw.txt.zip -d $PARA_PATH
fi

# en-th
if [ $pair == "en-th" ]; then
  echo "Download parallel data for English-Thai"
  # OpenSubtitles 2018
  wget -c http://opus.nlpl.eu/download.php?f=OpenSubtitles2018%2Fen-th.txt.zip -P $PARA_PATH
  unzip -u $PARA_PATH/download.php?f=OpenSubtitles2018%2Fen-th.txt.zip -d $PARA_PATH
fi

# en-tr
if [ $pair == "en-tr" ]; then
  echo "Download parallel data for English-Turkish"
  # OpenSubtitles 2018
  # wget -c http://opus.nlpl.eu/download.php?f=OpenSubtitles2018%2Fen-tr.txt.zip -P $PARA_PATH
  # SETIMES2
  wget -c http://opus.nlpl.eu/download.php?f=SETIMES2%2Fen-tr.txt.zip -P $PARA_PATH
  unzip -u $PARA_PATH/download.php?f=SETIMES2%2Fen-tr.txt.zip -d $PARA_PATH
  # Wikipedia
  wget -c http://opus.nlpl.eu/download.php?f=Wikipedia%2Fen-tr.txt.zip -P $PARA_PATH
  unzip -u $PARA_PATH/download.php?f=Wikipedia%2Fen-tr.txt.zip -d $PARA_PATH
  # TED
  wget -c https://object.pouta.csc.fi/OPUS-TED2013/v1.1/moses/en-tr.txt.zip -P $PARA_PATH
  unzip -u $PARA_PATH/en-tr.txt.zip -d $PARA_PATH
fi

# en-ur
if [ $pair == "en-ur" ]; then
  echo "Download parallel data for English-Urdu"
  # OpenSubtitles 2018
  # wget -c http://opus.nlpl.eu/download.php?f=OpenSubtitles2018%2Fen-ur.txt.zip -P $PARA_PATH
  # Tanzil
  wget -c http://opus.nlpl.eu/download.php?f=Tanzil%2Fen-ur.txt.zip -P $PARA_PATH
  unzip -u $PARA_PATH/download.php?f=Tanzil%2Fen-ur.txt.zip -d $PARA_PATH
fi

# en-vi
if [ $pair == "en-vi" ]; then
  echo "Download parallel data for English-Vietnamese"
  # OpenSubtitles 2018
  wget -c http://opus.nlpl.eu/download.php?f=OpenSubtitles2018%2Fen-vi.txt.zip -P $PARA_PATH
  unzip -u $PARA_PATH/download.php?f=OpenSubtitles2018%2Fen-vi.txt.zip -d $PARA_PATH
fi

# en-zh
if [ $pair == "en-zh" ]; then
  echo "Download parallel data for English-Chinese"
  # OpenSubtitles 2016
  # wget -c http://opus.nlpl.eu/download.php?f=OpenSubtitles2016%2Fen-zh.txt.zip -P $PARA_PATH
  # unzip -u $PARA_PATH/download.php?f=OpenSubtitles2016%2Fen-zh.txt.zip -d $PARA_PATH
  # MultiUN
  wget -c http://opus.nlpl.eu/download.php?f=MultiUN%2Fen-zh.txt.zip -P $PARA_PATH
  unzip -u $PARA_PATH/download.php?f=MultiUN%2Fen-zh.txt.zip -d $PARA_PATH
fi


if [ $pair == "de-hsb" ];then
  echo "Download WMT20 parallel data for German-Upper Sorbian"
  # we already have the valid and test data, just need train
  # Upper sorbian side
  wget -c http://www.statmt.org/wmt20/unsup_and_very_low_res/train.hsb-de.hsb.gz -P $PARA_PATH
  if [ ! -d $PARA_PATH/train.hsb-de.hsb ]; then
   gunzip -c $PARA_PATH/train.hsb-de.hsb.gz > $PARA_PATH/train.hsb-de.hsb
  fi

  wget -c http://www.statmt.org/wmt20/unsup_and_very_low_res/train.hsb-de.de.gz -P $PARA_PATH
  if [ ! -d $PARA_PATH/train.hsb-de.de ]; then
    gunzip -c $PARA_PATH/train.hsb-de.de.gz > $PARA_PATH/train.hsb-de.de
  fi

  # no need to split

  # tokenize
  for lg in $(echo $pair | sed -e 's/\-/ /g'); do
    # if [ ! -f $PARA_PATH/$pair.$lg.all ]; then
      # cat $PARA_PATH/*.$pair.$lg | $TOKENIZE $lg | python $LOWER_REMOVE_ACCENT > $PARA_PATH/$pair.$lg.all
      # removing bc the model i'm using only tokenizes, doesn't remove accents and lowercase
    cat $PARA_PATH/train.hsb-de.$lg | $TOKENIZE $lg > $PARA_PATH/$pair.$lg.all
    # fi
  done

  # binarize
  # reload BPE codes
  cd $MAIN_PATH
  echo "looking for BPE codes in: ${RELOAD_CODES}"
  cp $RELOAD_CODES $OUTPATH/codes

  echo "looking for vocab in: ${RELOAD_VOCAB}"
  cp $RELOAD_VOCAB $OUTPATH/vocab

  # fastBPE
  FASTBPE_DIR=$TOOLS_PATH/fastBPE
  FASTBPE=$TOOLS_PATH/fastBPE/fast

  for lg in $(echo $pair | sed -e 's/\-/ /g'); do
    $FASTBPE applybpe $OUTPATH/train.$pair.$lg $PARA_PATH/train.hsb-de.$lg $OUTPATH/codes
    python preprocess.py $OUTPATH/vocab $OUTPATH/train.$pair.$lg
  done

exit
fi


######## adding my own, non english centric pairs #########
# the process is the same for all the xnli data
if [ $SRC == "de" ]|| [ $TGT == "de" ];then
  echo "Download parallel data for German-${TGT}"
  # XNLI-15 way
  PARENT_PATH=$(dirname $PARA_PATH)
  wget -c https://dl.fbaipublicfiles.com/XNLI/XNLI-15way.zip -P $PARENT_PATH
  if [ ! -d $PARENT_PATH/XNLI-15way ]; then
    unzip $PARENT_PATH/XNLI-15way.zip -d $PARENT_PATH
  fi
  # for german and english, just cut the csv file 
  for lg in $(echo $pair | sed -e 's/\-/ /g'); do
    csvcut -t -c $lg $PARENT_PATH/XNLI-15way/xnli.15way.orig.tsv | csvcut -K 1 | csvformat -T  > $PARA_PATH/XNLI-15way.$pair.$lg
  done
  # reassigning these values bc the whole dataset is only 10k
  NTRAIN_SUB=1000
  NVAL_SUB=500
fi



#
# Tokenize and preprocess data
#

# tokenize
for lg in $(echo $pair | sed -e 's/\-/ /g'); do
  if [ ! -f $PARA_PATH/$pair.$lg.all ]; then
    # cat $PARA_PATH/*.$pair.$lg | $TOKENIZE $lg | python $LOWER_REMOVE_ACCENT > $PARA_PATH/$pair.$lg.all
    # removing bc the model i'm using only tokenizes, doesn't remove accents and lowercase
    cat $PARA_PATH/*.$pair.$lg | $TOKENIZE $lg > $PARA_PATH/$pair.$lg.all
  fi
done

# split into train / valid / test
split_data() {
    get_seeded_random() {
        seed="$1"; openssl enc -aes-256-ctr -pass pass:"$seed" -nosalt </dev/zero 2>/dev/null
    };
    NLINES=`wc -l $1  | awk -F " " '{print $1}'`;

    NTRAIN=$((NLINES - NTRAIN_SUB));
    NVAL=$((NTRAIN + NVAL_SUB));
    shuf --random-source=<(get_seeded_random 42) $1 | head -$NTRAIN             > $2;
    shuf --random-source=<(get_seeded_random 42) $1 | head -$NVAL | tail -$NVAL_SUB  > $3;
    shuf --random-source=<(get_seeded_random 42) $1 | tail -$NVAL_SUB                > $4;
}


for lg in $(echo $pair | sed -e 's/\-/ /g'); do
  split_data $PARA_PATH/$pair.$lg.all $PARA_PATH/train.$pair.$lg $PARA_PATH/valid.$pair.$lg $PARA_PATH/test.$pair.$lg
done

echo "has been successfully split!"
## adding the binarization here
# reload BPE codes
cd $MAIN_PATH
echo "looking for BPE codes in"
echo ${RELOAD_CODES}
cp $RELOAD_CODES $OUTPATH/codes

echo "looking for vocab in"
echo ${RELOAD_VOCAB}
cp $RELOAD_VOCAB $OUTPATH/vocab


# fastBPE
FASTBPE_DIR=$TOOLS_PATH/fastBPE
FASTBPE=$TOOLS_PATH/fastBPE/fast

for lg in $(echo $pair | sed -e 's/\-/ /g'); do
  for split in train valid test; do
    $FASTBPE applybpe $OUTPATH/$split.$pair.$lg $PARA_PATH/$split.$pair.$lg $OUTPATH/codes
    python preprocess.py $OUTPATH/vocab $OUTPATH/$split.$pair.$lg
  done
done

