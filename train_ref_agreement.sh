#!/usr/bin/env bash

export COMET_MODE=ONLINE
export COMET_API_KEY="ZVTkXN5kScnbV6H4uBBZ97Qyv"
export COMET_PROJECT_NAME='low-resource-mt'


# WE ARE TRAINING AN EN-->RO MODEL WITH French (Fr) AS A REFERENCE LANGUAGE
python ./train.py \
--exp_name unsupMT_en_fr_ro \
--dump_path ${NMT_EXP_DIR}/dumped/ \
--reload_model "mlm_100_1280.pth,mlm_100_1280.pth" \
--data_path "${NMT_DATA_DIR}/processed/" \
--lgs 'en-fr-ro' \
--ae_steps 'ro,en,fr' \
--mt_steps 'en-fr' \
--bt_steps 'en-ro-en,ro-en-ro' \
--rat_steps 'en-fr-ro' \
--word_shuffle 3 \
--word_dropout 0.1 \
--word_blank 0.1 \
--lambda_ae '0:1,100000:0.1,300000:0' \
--encoder_only false \
--emb_dim 1280 \
--n_layers 6 \
--n_heads 8 \
--dropout 0.1 \
--attention_dropout 0.1 \
--gelu_activation true \
<<<<<<< HEAD
--batch_size 2 \
--max_vocab 200000 \
--optimizer adam_inverse_sqrt,beta1=0.9,beta2=0.98,lr=0.0001 \
--epoch_size 100 \
--eval_bleu true \
--stopping_criterion 'valid_en-de_mt_bleu,3' \
--validation_metrics 'valid_en-de_mt_bleu' \
--amp 2 \
--accumulate_gradients 4 \
--fp16 true \
# --master_port -1
# --local_rank -1 \
# --debug_train true \
# --debug_slurm true \
# --bptt 32 \
# --max_len 200 \
# --tokens_per_batch 80 \
# --rabt_steps 'ar-en-de-ar-en' \
# --xbt_steps \

#bptt was 256
# batch_size wasn't set
# tokens_per_batch was 2000
=======
--tokens_per_batch 500 \
--batch_size 32 \
--bptt 256 \
--max_len 200 \
--max_vocab 200000 \
--optimizer adam_inverse_sqrt,beta1=0.9,beta2=0.98,lr=0.0001 \
--epoch_size 20000 \
--eval_bleu true \
--stopping_criterion 'valid_en-de_mt_bleu,3' \
--validation_metrics 'valid_en-de_mt_bleu' \
--debug_slurm true \
--amp 1 \
--accumulate_gradients 4 \
--fp16 true \
# --debug_train true \



# --rabt_steps 'ar-en-de-ar-en' \
# --xbt_steps \

>>>>>>> adding_langs
# note: batchsize is for back_translation