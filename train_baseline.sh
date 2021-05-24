#!/usr/bin/env bash 
export COMET_MODE=ONLINE
export COMET_API_KEY="ZVTkXN5kScnbV6H4uBBZ97Qyv"
export COMET_PROJECT_NAME='unsupMT'

# export PATH=/home/hem52/.conda/envs/nmt/bin:$PATH

# export NGPU=1; python -m torch.distributed.launch --nproc_per_node=$NGPU train.py \
# WE ARE TRAINING A DE-->HSB MODEL with NO reference language


# export NGPU=4; python -m torch.distributed.launch --nproc_per_node=$NGPU train.py \
python ./train.py \
--exp_name de_hsb_baseline \
--dump_path ${NMT_EXP_DIR}/dumped/ \
--data_path "${NMT_DATA_DIR}/processed/" \
--reload_model "${NMT_EXP_DIR}/dumped/finetune_de_hsb_mlm_full-vocab/40631027/best-valid_hsb_mlm_ppl.pth,${NMT_EXP_DIR}/dumped/finetune_de_hsb_mlm_full-vocab/40631027/best-valid_hsb_mlm_ppl.pth" \
--lgs "de-hsb" \
--max_vocab 123709 \
--ae_steps "de,hsb" \
--lambda_ae '0:1,100000:0.1,300000:0' \
--bt_steps "de-hsb-de,hsb-de-hsb" \
--log_int 100 \
--epsilon 0.1 \
--word_shuffle 3 \
--word_dropout 0.1 \
--word_blank 0.1 \
--encoder_only false \
--emb_dim 1024 \
--n_layers 6 \
--n_heads 8 \
--dropout 0.1 \
--attention_dropout 0.1 \
--gelu_activation true \
--tokens_per_batch 500 \
--bptt 256 \
--max_len 200 \
--optimizer adam_inverse_sqrt,beta1=0.9,beta2=0.98,lr=0.0001 \
--epoch_size 20000 \
--eval_bleu true \
--stopping_criterion 'valid_de-hsb_mt_bleu,10' \
--validation_metrics 'valid_de-hsb_mt_bleu,valid_hsb-de_mt_bleu' \
--debug_train false \
--debug_slurm true \
--amp 1 \
--fp16 true \
--accumulate_gradients 4 \
--use_pretrained_lang_emb \
--beam_size 1

# 

# --data_path "${NMT_DATA_DIR}/xlm_processed/de-hsb/30k" \
# --reload_model "${NMT_EXP_DIR}/dumped/de_hsb_wmt_xlm/40773871/best-valid_mlm_ppl.pth,${NMT_EXP_DIR}/dumped/de_hsb_wmt_xlm/40773871/best-valid_mlm_ppl.pth" \
# --reload_model "mlm_tlm_xnli15_1024.pth,mlm_tlm_xnli15_1024.pth" \

# 31250
# --batch_size 32 \

# --accumulate_gradients 4 \
# --lambda_bt '0:1,100000:0.1,300000:0' \
# ${NMT_EXP_DIR}/dumped/finetune_de_hsb_mlm_no_ext/40724701/best-valid_mlm_ppl.pth
# --reload_model "${NMT_EXP_DIR}/dumped/finetune_de_hsb_mlm_no_ext/40646546/best-valid_mlm_ppl.pth,${NMT_EXP_DIR}/dumped/finetune_de_hsb_mlm_no_ext/40646546/best-valid_mlm_ppl.pth" \
# --reload_checkpoint '${NMT_EXP_DIR}/dumped/de_hsb_baseline_no-ext_no-ft/40646546/checkpoint.pth' \
# --master_port 10001 \
# "${NMT_EXP_DIR}/dumped/finetune_de_hsb_mlm_no_ext/40724701/best-valid_mlm_ppl.pth,${NMT_EXP_DIR}/dumped/finetune_de_hsb_mlm_no_ext/40724701/best-valid_mlm_ppl.pth"    \
# if not debug_slurm, need
# --mt_steps "de-en" \
# --lambda_mt '0:1,100000:0.1,300000:0' \
# --tokens_per_batch 1000 \


# --bt_steps "de-hsb-de,hsb-de-hsb" \
# --increase_vocab_for_lang de  \
# --increase_vocab_from_lang hsb \
# --lambda_bt '0:1,100000:0.1,300000:0' \
# --lambda_mt '0:1,100000:0.1,300000:0' \
# --reload_model "${NMT_EXP_DIR}/dumped/finetune_de_hsb_mlm/38967777/best-valid_hsb_mlm_ppl.pth,${NMT_EXP_DIR}/dumped/finetune_de_hsb_mlm/38967777/best-valid_hsb_mlm_ppl.pth" \
