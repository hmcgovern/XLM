#!/bin/bash
# This script is meant to prepare data for reference-agreement based UNMT
#

set -e

pair=$1  # input language pair


# data paths
MAIN_PATH=$PWD
PARA_PATH=${NMT_EXP_DIR}/data/xnli_para
TOOLS_PATH=$PWD/tools
WIKI_PATH=${NMT_EXP_DIR}/data/wiki
# XNLI_PATH=${NMT_EXP_DIR}/data/xnli/XNLI-1.0
PROCESSED_PATH=${NMT_EXP_DIR}/data/processed/runmt
CODES_PATH=${NMT_EXP_DIR}/models/codes_xnli_15
VOCAB_PATH=${NMT_EXP_DIR}/models/vocab_xnli_15
FASTBPE=$TOOLS_PATH/fastBPE/fast

mkdir -p $PROCESSED_PATH

## Prepare monolingual data
# apply BPE codes and binarize the monolingual corpora
# for lg in ar bg de el en es fr hi ru sw th tr ur vi zh; do

# for lg in ar de en; do
# for lg in de en; do
#     for split in train valid test; do
#         $FASTBPE applybpe $PROCESSED_PATH/$split.$lg $WIKI_PATH/txt/$lg.$split $CODES_PATH
#         python preprocess.py $VOCAB_PATH $PROCESSED_PATH/$split.$lg
#         # $FASTBPE applybpe $PROCESSED_PATH/$lg.$split $WIKI_PATH/txt/$lg.$split $CODES_PATH
#         # python preprocess.py $VOCAB_PATH $PROCESSED_PATH/$lg.$split
#     done
# done

# Prepare parallel data
# apply BPE codes and binarize the parallel corpora
# for pair in ar-en bg-en de-en el-en en-es en-fr en-hi en-ru en-sw en-th en-tr en-ur en-vi en-zh; do
for pair in ar-en de-en; do 
    for lg in $(echo $pair | sed -e 's/\-/ /g'); do
        for split in train valid test; do
            $FASTBPE applybpe $PROCESSED_PATH/$split.$pair.$lg $PARA_PATH/$pair.$lg.$split $CODES_PATH
            python preprocess.py $VOCAB_PATH $PROCESSED_PATH/$split.$pair.$lg
            # $FASTBPE applybpe $PROCESSED_PATH/$pair.$lg.$split $PARA_PATH/$pair.$lg.$split $CODES_PATH
            # python preprocess.py $VOCAB_PATH $PROCESSED_PATH/$pair.$lg.$split
            
        done
    done
done
