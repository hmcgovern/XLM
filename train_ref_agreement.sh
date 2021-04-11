#!/usr/bin/env bash

export COMET_MODE=ONLINE
export COMET_API_KEY="ZVTkXN5kScnbV6H4uBBZ97Qyv"
export COMET_PROJECT_NAME='low-resource-mt'


# WE ARE TRAINING AN EN-->DE MODEL WITH French (Fr) AS A REFERENCE LANGUAGE
python ./train.py \
--exp_name unsupMT_en_fr_de \
--dump_path ${NMT_EXP_DIR}/dumped/ \
--reload_model "mlm_tlm_xnli15_1024.pth,mlm_tlm_xnli15_1024.pth" \
--data_path "${NMT_DATA_DIR}/exp/en_fr_de/" \
--lgs 'en-fr-de' \
--ae_steps 'en,fr,de' \
--mt_steps 'en-fr' \
--bt_steps '' \
--rat_steps 'en-fr-de' \
--epsilon 0.1 \
--word_shuffle 3 \
--word_dropout 0.1 \
--word_blank 0.1 \
--lambda_ae '0:1,100000:0.1,300000:0' \
--encoder_only false \
--emb_dim 1024 \
--n_layers 6 \
--n_heads 8 \
--dropout 0.1 \
--attention_dropout 0.1 \
--gelu_activation true \
--tokens_per_batch 500 \
--batch_size 32 \
--bptt 256 \
--max_len 100 \
--optimizer adam_inverse_sqrt,beta1=0.9,beta2=0.98,lr=0.0001 \
--epoch_size 2000 \
--eval_bleu true \
--stopping_criterion 'valid_en-de_mt_bleu,10' \
--validation_metrics 'valid_en-de_mt_bleu' \
--debug_train true \
--use_lang_emb false \
--max_vocab 95000 \
# --amp 2 \
# --accumulate_gradients 4 \
# --fp16 true \

# --bptt 256 \

# --ae_steps 'en,fr,de' \
# --mt_steps 'en-fr' \
# --bt_steps 'en-fr-en,fr-en-fr' \