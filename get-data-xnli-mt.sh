# Copyright (c) 2019-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed under the license found in the
# LICENSE file in the root directory of this source tree.
#

#
# Usage: ./get-data-xnli.sh
#

set -e

# data paths
MAIN_PATH=$PWD
OUTPATH=$NMT_DATA_DIR/xnli
XNLI_PATH=$NMT_DATA_DIR/xnli/XNLI-15way
CODES=$MAIN_PATH/codes_xnli_15
VOCAB=$MAIN_PATH/vocab_xnli_15

PROC_PATH=$NMT_DATA_DIR/xnli/processed

# tools paths
TOOLS_PATH=$PWD/tools
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
# we've got a .tsv we need to separate into indivual languages, split, tokenize, and binarize. shouldn't be too too bad. 


for lg in de en fr zh; do
    echo "*** Preparing $lg data ***"
    # since I don't know the column number, I can't use awk easily. Installing a specialized package called csvkit to help
    if [ ! -f $XNLI_PATH/$lg.all ]; then
        csvcut -t -c $lg $XNLI_PATH/xnli.15way.orig.tsv | csvcut -K 1 | csvformat -T | $TOKENIZE $lg | python $LOWER_REMOVE_ACCENT > $XNLI_PATH/$lg.all
    fi
done

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


for lg in de en fr zh; do
  split_data $XNLI_PATH/$lg.all $XNLI_PATH/train.$lg $XNLI_PATH/valid.$lg $XNLI_PATH/test.$lg
done



# fastBPE
FASTBPE_DIR=$TOOLS_PATH/fastBPE
FASTBPE=$TOOLS_PATH/fastBPE/fast

for lg in de en fr zh; do
  for split in train valid test; do
    $FASTBPE applybpe $PROC_PATH/$split.$lg $XNLI_PATH/$split.$lg $CODES
    python preprocess.py $VOCAB $PROC_PATH/$split.$lg
  done
done


###################
#
# Tokenize and preprocess data
#

# # tokenize
# for lg in $(echo $pair | sed -e 's/\-/ /g'); do
#   if [ ! -f $PARA_PATH/$pair.$lg.all ]; then
#     cat $PARA_PATH/*.$pair.$lg | $TOKENIZE $lg | python $LOWER_REMOVE_ACCENT > $PARA_PATH/$pair.$lg.all
#     # removing bc the model i'm using only tokenizes, doesn't remove accents and lowercase
#     # cat $PARA_PATH/*.$pair.$lg | $TOKENIZE $lg > $PARA_PATH/$pair.$lg.all
#   fi
# done





# echo "has been successfully split!"
# ## adding the binarization here
# # reload BPE codes
# cd $MAIN_PATH
# echo "looking for BPE codes in"
# echo ${RELOAD_CODES}


##################

# # English train set
# echo "*** Preparing English train set ****"
# echo -e "premise\thypo\tlabel" > $XNLI_PATH/en.train
# sed '1d'  $OUTPATH/XNLI-MT-1.0/multinli/multinli.train.en.tsv | cut -f1 | python $LOWER_REMOVE_ACCENT > $XNLI_PATH/train.f1
# sed '1d'  $OUTPATH/XNLI-MT-1.0/multinli/multinli.train.en.tsv | cut -f2 | python $LOWER_REMOVE_ACCENT > $XNLI_PATH/train.f2
# sed '1d'  $OUTPATH/XNLI-MT-1.0/multinli/multinli.train.en.tsv | cut -f3 | sed 's/contradictory/contradiction/g' > $XNLI_PATH/train.f3
# paste $XNLI_PATH/train.f1 $XNLI_PATH/train.f2 $XNLI_PATH/train.f3 >> $XNLI_PATH/en.train

# rm $XNLI_PATH/train.f1 $XNLI_PATH/train.f2 $XNLI_PATH/train.f3


# # validation and test sets
# for lg in ar bg de el en es fr hi ru sw th tr ur vi zh; do

#   echo "*** Preparing $lg validation and test sets ***"
#   echo -e "premise\thypo\tlabel" > $XNLI_PATH/$lg.valid
#   echo -e "premise\thypo\tlabel" > $XNLI_PATH/$lg.test

#   # label
#   awk -v lg=$lg '$1==lg' $XNLI_PATH/xnli.dev.tsv  | cut -f2 > $XNLI_PATH/dev.f2
#   awk -v lg=$lg '$1==lg' $XNLI_PATH/xnli.test.tsv | cut -f2 > $XNLI_PATH/test.f2

#   # premise/hypothesis
#   awk -v lg=$lg '$1==lg' $XNLI_PATH/xnli.dev.tsv  | cut -f7 | $TOKENIZE $lg | python $LOWER_REMOVE_ACCENT > $XNLI_PATH/dev.f7
#   awk -v lg=$lg '$1==lg' $XNLI_PATH/xnli.dev.tsv  | cut -f8 | $TOKENIZE $lg | python $LOWER_REMOVE_ACCENT > $XNLI_PATH/dev.f8
#   awk -v lg=$lg '$1==lg' $XNLI_PATH/xnli.test.tsv | cut -f7 | $TOKENIZE $lg | python $LOWER_REMOVE_ACCENT > $XNLI_PATH/test.f7
#   awk -v lg=$lg '$1==lg' $XNLI_PATH/xnli.test.tsv | cut -f8 | $TOKENIZE $lg | python $LOWER_REMOVE_ACCENT > $XNLI_PATH/test.f8

#   paste $XNLI_PATH/dev.f7  $XNLI_PATH/dev.f8  $XNLI_PATH/dev.f2  >> $XNLI_PATH/$lg.valid
#   paste $XNLI_PATH/test.f7 $XNLI_PATH/test.f8 $XNLI_PATH/test.f2 >> $XNLI_PATH/$lg.test

#   rm $XNLI_PATH/*.f2 $XNLI_PATH/*.f7 $XNLI_PATH/*.f8
# done
