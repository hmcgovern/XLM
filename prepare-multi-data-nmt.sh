#!/bin/bash
# This script is meant to prepare data for reference-agreement based UNMT
#

set -e

# lg=$1 # input language
pair=$1  # input language pair


# data paths
MAIN_PATH=$PWD
PARA_PATH=./data/runmt_para
# PARA_PATH=$3
TOOLS_PATH=$PWD/tools
# WIKI_PATH=${NMT_EXP_DIR}/data/wiki
# WIKI_PATH=$4
PROCESSED_PATH=./data/processed/runmt
# PROCESSED_PATH=$5
CODES_PATH=codes_xnli_17
# CODES_PATH=$6
VOCAB_PATH=vocab_xnli_17
# VOCAB_PATH=$7
FASTBPE=$TOOLS_PATH/fastBPE/fast

mkdir -p $PROCESSED_PATH

## Prepare monolingual data
# apply BPE codes and binarize the monolingual corpora
# for lg in ar bg de el en es fr hi ru sw th tr ur vi zh; do
# for lg in ar de en; do
#     for split in train valid test; do
#         $FASTBPE applybpe $PROCESSED_PATH/$split.$lg $WIKI_PATH/txt/$lg.$split $CODES_PATH
#         python preprocess.py $VOCAB_PATH $PROCESSED_PATH/$split.$lg
#     done
# done


# Prepare parallel data
# apply BPE codes and binarize the parallel corpora
# for pair in ar-en bg-en de-en el-en en-es en-fr en-hi en-ru en-sw en-th en-tr en-ur en-vi en-zh; do

for lg in $(echo $pair | sed -e 's/\-/ /g'); do
    for split in train valid test; do
        $FASTBPE applybpe $PROCESSED_PATH/$split.$pair.$lg $PARA_PATH/$pair.$lg.$split $CODES_PATH
        python preprocess.py $VOCAB_PATH $PROCESSED_PATH/$split.$pair.$lg
    done
done


