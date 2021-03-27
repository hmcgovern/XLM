#!/usr/bin/env bash

export COMET_MODE=ONLINE
export COMET_API_KEY="ZVTkXN5kScnbV6H4uBBZ97Qyv"
export COMET_PROJECT_NAME='low-resource-mt'
export COMET_DISABLE_AUTO_LOGGING=1

## main parameters
# export CUDA_VISIBLE_DEVICES=0,1
# this is for multi GPU training:
# 
# python ./XLM/train.py \
export NGPU=4; python -m torch.distributed.launch --nproc_per_node=$NGPU ./train.py \
--exp_name unsupMT_ende \
--dump_path ${NMT_EXP_DIR}/dumped/ \
--reload_model "mlm_ende_1024.pth,mlm_ende_1024.pth" \
--data_path ./data/processed/de-en/ \
--lgs 'de-en' \
--ae_steps 'de,en' \
--bt_steps 'de-en-de,en-de-en' \
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
--tokens_per_batch 2000 \
--amp 2 \
--accumulate_gradients 4 \
--batch_size 32 \
--bptt 256 \
--optimizer adam_inverse_sqrt,beta1=0.9,beta2=0.98,lr=0.0001 \
--epoch_size 200000 \
--eval_bleu true \
--stopping_criterion 'valid_en-de_mt_bleu,10' \
--validation_metrics 'valid_en-de_mt_bleu' \
--local_rank -1 \
--debug_train true \
# --debug_slurm true \
# when i run it interactively, local rank is 3





# note: batchsize is for back_translation