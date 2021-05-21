#!/usr/bin/env bash 
export COMET_MODE=ONLINE
export COMET_API_KEY="ZVTkXN5kScnbV6H4uBBZ97Qyv"
export COMET_PROJECT_NAME='XLM'

# export PATH=/home/hem52/.conda/envs/nmt/bin:$PATH

# export NGPU=1; python -m torch.distributed.launch --nproc_per_node=$NGPU train.py \
# WE ARE TRAINING A DE-->HSB XLM MODEL 


# export NGPU=4; python -m torch.distributed.launch --nproc_per_node=$NGPU train.py \
python ./train.py \
--exp_name de_hsb_wmt_xlm \
--dump_path ${NMT_EXP_DIR}/dumped/ \
--data_path "${NMT_DATA_DIR}/xlm_processed/de-hsb/30k" \
--lgs "de-hsb" \
--mlm_steps "de,hsb" \
--encoder_only false \
--emb_dim 512 \
--n_layers 8 \
--n_heads 8 \
--dropout 0.1 \
--attention_dropout 0.1 \
--gelu_activation true \
--batch_size 16 \
--bptt 256 \
--optimizer adam,lr=0.0001 \
--epoch_size 10000 \
--stopping_criterion '_valid_mlm_ppl,10' \
--validation_metrics '_valid_mlm_ppl' \
--debug_train false \
--debug_slurm true \
--amp 1 \
--fp16 true \
# 