#!/usr/bin/env bash

export COMET_MODE=ONLINE
export COMET_API_KEY="ZVTkXN5kScnbV6H4uBBZ97Qyv"
export COMET_PROJECT_NAME='low-resource-mt'


# WE ARE TRAINING AN EN-->DE MODEL WITH ARABIC (AR) AS A REFERENCE LANGUAGE
python ./train.py \
--exp_name unsupMT_ar_de_en \
--dump_path ${NMT_EXP_DIR}/dumped/ \
--reload_model "${NMT_EXP_DIR}/models/mlm_tlm_xnli15_1024.pth,${NMT_EXP_DIR}/models/mlm_tlm_xnli15_1024.pth" \
--data_path "${NMT_EXP_DIR}/data/processed/runmt" \
--lgs 'de-en-ar' \
--ae_steps 'de,en,ar' \
--mt_steps 'en-ar' \
--bt_steps 'de-en-de,en-de-en' \
--rat_steps 'ar-en-de' \
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
--stopping_criterion 'valid_en-de_mt_bleu,3' \
--validation_metrics 'valid_en-de_mt_bleu' \
--debug_slurm true \
--amp 1 \
--accumulate_gradients 4 \
--fp16 true 
# --debug_train true \



# --rabt_steps 'ar-en-de-ar-en' \
# --xbt_steps \

# note: batchsize is for back_translation