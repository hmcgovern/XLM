#!/usr/bin/env bash

# LANG1=$1 # en
# LANG2=$2 # de

# wget https://dl.fbaipublicfiles.com/XLM/codes_ende
# wget https://dl.fbaipublicfiles.com/XLM/vocab_ende


./get-data-nmt.sh --src de --tgt en --reload_codes codes_ende --reload_vocab vocab_ende