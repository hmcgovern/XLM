#!/usr/bin/env bash 
export COMET_MODE=ONLINE
export COMET_API_KEY="ZVTkXN5kScnbV6H4uBBZ97Qyv"
export COMET_PROJECT_NAME='mRUNMT Project Experiments'

# export PATH=/home/hem52/.conda/envs/nmt/bin:$PATH

# export NGPU=1; python -m torch.distributed.launch --nproc_per_node=$NGPU train.py \
# WE ARE TRAINING A DE-->HSB MODEL with NO reference language


# export NGPU=4; python -m torch.distributed.launch --nproc_per_node=$NGPU train.py \
python ./train.py \
--exp_name exp1 \
--dump_path ${NMT_EXP_DIR}/dumped/ \
--data_path "${NMT_DATA_DIR}/xlm_processed/de-hsb/30k" \
--reload_model "${NMT_EXP_DIR}/dumped/de_hsb_wmt_xlm/40773871/best-valid_mlm_ppl.pth,${NMT_EXP_DIR}/dumped/de_hsb_wmt_xlm/40773871/best-valid_mlm_ppl.pth" \
--lgs "de-hsb" \
--max_vocab -1 \
--ae_steps "de,hsb" \
--lambda_ae '0:1,100000:0.1,300000:0' \
--bt_steps "de-hsb-de,hsb-de-hsb" \
--log_int 100 \
--max_len 200 \
--epsilon 0.1 \
--word_shuffle 3 \
--word_dropout 0.1 \
--word_blank 0.1 \
--encoder_only false \
--emb_dim 512 \
--n_layers 8 \
--n_heads 8 \
--dropout 0.1 \
--attention_dropout 0.1 \
--gelu_activation true \
--tokens_per_batch 500 \
--bptt 256 \
--optimizer adam_inverse_sqrt,beta1=0.9,beta2=0.98,lr=0.0001 \
--epoch_size 100000 \
--eval_bleu true \
--stopping_criterion 'valid_de-hsb_mt_bleu,10' \
--validation_metrics 'valid_de-hsb_mt_bleu' \
--debug_train false \
--debug_slurm true \
--amp 1 \
--fp16 true \
--accumulate_gradients 4 \

