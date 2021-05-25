# this is a script to process the biblical corpora.
# the naming convention is a 3-letter language code, there could be multiple of the same language
# structure of a single document is a line number and then the sentence. Need to grab only the second column. csv_kit? 
# 1. We want to search for all, e.g. aau*.txt and concatenate them into aau.all.
# but I suppose we can only use these as parallel corpora if we use just one translation. So for now, let's only bother with one
set -e

#
# Read arguments
#
POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"
case $key in
  --lgs)
    lgs="$2"; shift 2;;
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

# lg=$1


# data paths
MAIN_PATH=${XLM_REPO_DIR}
OUTPATH=${NMT_DATA_DIR}/bible_processed/
DATA_PATH=${NMT_DATA_DIR}/bibles
# PROC_PATH=$NMT_DATA_DIR/xlm_processed/bible/processed/$lg

# tools paths
TOOLS_PATH=${XLM_REPO_DIR}/tools
TOKENIZE=$TOOLS_PATH/tokenize.sh
LOWER_REMOVE_ACCENT=$TOOLS_PATH/lowercase_and_remove_accent.py

# fastBPE
FASTBPE_DIR=$TOOLS_PATH/fastBPE
FASTBPE=$TOOLS_PATH/fastBPE/fast

# create directories
mkdir -p $OUTPATH
# mkdir -p $PROC_PATH



# train / valid / test monolingual BPE data
TRAIN_BPE=$OUTPATH/train.$lg
VALID_BPE=$OUTPATH/valid.$lg
TEST_BPE=$OUTPATH/test.$lg

# for parallel data, might need to symlink it
# bc eng-aau data is just the monolingual eng + aau sets

# BPE / vocab files
# BPE_CODES=$PROC_PATH/codes
# FULL_VOCAB=$PROC_PATH/vocab

for lg in $(echo $lgs | sed -e 's/\-/ /g'); do
  # raw and tokenized files
  RAW=$OUTPATH/all.$lg
  TOK=$RAW.tok

  # concatenate monolingual data files
  if [[ -f "$RAW" ]]; then
    echo "Removing existing text file..."
    rm $RAW
  fi
  echo "Concatenating $lg monolingual data..."


  # paths to exclude: "/rds/user/hem52/hpc-work/data/bibles/bul_1443.biblecom.txt"
  for FILENAME in $DATA_PATH/$lg*.txt; do
    # if the name has biblecom, scrub the first 
    if [[ "$FILENAME" == *"biblecom"* ]]; then
      # echo $FILENAME
      wc -l $FILENAME
      eval "cat $FILENAME >> $RAW"
      # eval "cat $FILENAME | csvcut -tc 2  >> $RAW"
    # else
    #   eval "cat $FILENAME >> $RAW "
    fi

  done
done


exit 
echo "*** Extracting $lg data from the tsv file ***"
# # since I don't know the column number, I can't use awk easily. Installing a specialized package called csvkit to help
# if [ ! -f $SRC_TRAIN ]; then
#     # csvcut -t -c $lg $XNLI_PATH/xnli.15way.orig.tsv | csvcut -K 1 | csvformat -T | $TOKENIZE $lg | python $LOWER_REMOVE_ACCENT > $XNLI_PATH/$lg.all
#     csvcut -t -c $lg $XNLI_PATH/xnli.15way.orig.tsv | csvcut -K 1 | csvformat -T  > $SRC_TRAIN
# fi

# 2. Then we pass aau.all through the tokenizer/lowercase/remove accents --> aau.all.tok
# 3. That gets split into train/valid/test
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

# 4. Encode with BPE
# 5. Binarize (to .pth)
# as for which bibles we want to target, let's look at like 5 slavic languages: slk, rus, ukr, bul

# and 5 germanic languages: english (eng) swedish (swe) afrikaans (afr), danish (dan), norwegian (nno)

# as well as single ref of bg, ru, hi, ar, and en for comparison 