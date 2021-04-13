#!/usr/bin/env bash


# # downloading 15 lg pretrained XLM & associated files
# wget -c https://dl.fbaipublicfiles.com/XLM/mlm_tlm_xnli15_1024.pth
# wget -c https://dl.fbaipublicfiles.com/XLM/codes_xnli_15
# wget -c https://dl.fbaipublicfiles.com/XLM/vocab_xnli_15

# # # # collect monolingual training data for 4 langs: en, zh, fr, and de
# ./get-data-nmt.sh --src en --tgt zh --reload_codes /${NMT_REPO_DIR}/XLM/codes_xnli_15 --reload_vocab /${NMT_REPO_DIR}/XLM/vocab_xnli_15
# ./get-data-nmt.sh --src en --tgt fr --reload_codes /${NMT_REPO_DIR}/XLM/codes_xnli_15 --reload_vocab /${NMT_REPO_DIR}/XLM/vocab_xnli_15
# ./get-data-nmt.sh --src de --tgt en --reload_codes /${NMT_REPO_DIR}/XLM/codes_xnli_15 --reload_vocab /${NMT_REPO_DIR}/XLM/vocab_xnli_15


# the parallel is really for english, this is where the bible corpus would come in, bc
# it's massively multilingual
# also collect en-fr and en-zh for the ref language
for lg_pair in "en-zh"; do # "en-fr"  "en-zh"
  ./get-data-para.sh $lg_pair /${NMT_REPO_DIR}/XLM/codes_xnli_15 /${NMT_REPO_DIR}/XLM/vocab_xnli_15
done




