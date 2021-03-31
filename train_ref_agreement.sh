#!/usr/bin/env bash

export COMET_MODE=ONLINE
export COMET_API_KEY="ZVTkXN5kScnbV6H4uBBZ97Qyv"
export COMET_PROJECT_NAME='low-resource-mt'


# WE ARE TRAINING AN EN-->DE MODEL WITH French (Fr) AS A REFERENCE LANGUAGE
python ./train.py \
--exp_name unsupMT_fr_de_en \
--dump_path ${NMT_EXP_DIR}/dumped/ \
--reload_model "mlm_17_1280.pth,mlm_17_1280.pth" \
--data_path "./data/processed/all/" \
--lgs 'de-en-fr' \
--ae_steps 'de,en,fr' \
--mt_steps 'en-fr' \
--bt_steps 'de-en-de,en-de-en' \
--rat_steps 'fr-en-de' \
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