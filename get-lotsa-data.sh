#!/usr/bin/env bash

# cd ${NMT_EXP_DIR}/models

# wget https://dl.fbaipublicfiles.com/XLM/mlm_tlm_xnli15_1024.pth
# wget https://dl.fbaipublicfiles.com/XLM/codes_xnli_15
# wget https://dl.fbaipublicfiles.com/XLM/vocab_xnli_15



# ar bg de el en es fr hi ru sw th tr ur vi zh
for lg in ar de en es fr hi ru; do
  ./get-data-wiki.sh $lg
done


# the parallel is really for english, this is where the bible corpus would come in, bc
# it's massively multilingual
# "ar-en bg-en de-en el-en en-es en-fr en-hi en-ru en-sw en-th en-tr en-ur en-vi en-zh"
lg_pairs="ar-en de-en en-es en-fr en-hi en-ru"
for lg_pair in $lg_pairs; do
  ./get-data-para.sh $lg_pair
done
