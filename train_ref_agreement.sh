#!/usr/bin/env bash

export COMET_MODE=ONLINE
export COMET_API_KEY="ZVTkXN5kScnbV6H4uBBZ97Qyv"
export COMET_PROJECT_NAME='low-resource-mt'


ref=fr

# WE ARE TRAINING AN EN-->DE MODEL WITH French (Fr) AS A REFERENCE LANGUAGE
python ./train.py \
--exp_name unsupMT_en_${ref}_de \
--dump_path ${NMT_EXP_DIR}/dumped/ \
--reload_model "mlm_tlm_xnli15_1024.pth,mlm_tlm_xnli15_1024.pth" \
--data_path "${NMT_DATA_DIR}/exp/en_${ref}_de/" \
--lgs "en-${ref}-de" \
--ae_steps "en,${ref},de" \
--mt_steps "en-${ref}" \
--bt_steps "en-de-en,de-en-de" \
--rat_steps "en-${ref}-de" \
--rabt_steps "en-${ref}-de,${ref}-en-de" \
--xbt_steps "en-de-${ref},${ref}-de-en" \
--log_int 20 \
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
--tokens_per_batch 1000 \
--batch_size 32 \
--bptt 256 \
--max_len 200 \
--optimizer adam_inverse_sqrt,beta1=0.9,beta2=0.98,lr=0.0001 \
--epoch_size 20000 \
--eval_bleu true \
--stopping_criterion 'valid_en-de_mt_bleu,10' \
--validation_metrics 'valid_en-de_mt_bleu' \
--debug_train false \
--use_lang_emb false \
--max_vocab 95000 \
# --amp 2 \
# --accumulate_gradients 4 \
# --fp16 true \
# --lambda_bt '0:0,500:0,2000:1' \
# --lambda_rat '0:0,500:0,2000:1' \
# --lambda_rabt '0:0,500:0,2000:1' \
# --lambda_xbt '0:0,500:0,2000:1' \

