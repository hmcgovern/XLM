#!/usr/bin/env bash 
export COMET_MODE=ONLINE
export COMET_API_KEY="ZVTkXN5kScnbV6H4uBBZ97Qyv"
export COMET_PROJECT_NAME='unsupMT'


MT_STEPS="de-hsb,"
RABT_STEPS=""
XBT_STEPS=""
LIST=""

for ref in $@; do
    MT_STEPS+="de-${ref},"
    RABT_STEPS+="de-${ref}-hsb,${ref}-de-hsb,"
    XBT_STEPS+="de-hsb-${ref},${ref}-hsb-de,"
    LIST+="${ref}_"
done

# prune the trailing comma
MT_STEPS=${MT_STEPS/%,}
RABT_STEPS=${RABT_STEPS/%,}
XBT_STEPS=${XBT_STEPS/%,}


echo "MT: " $MT_STEPS 
echo "RABT: " $RABT_STEPS 
echo "XBT: " $XBT_STEPS

# exit

# WE ARE TRAINING A DE-->HSB MODEL 

# export NGPU=2; python -m torch.distributed.launch --nproc_per_node=$NGPU train.py \
python ./train.py \
--exp_name "de_${LIST}hsb_8k" \
--dump_path ${NMT_EXP_DIR}/dumped/ \
--reload_model "${NMT_EXP_DIR}/dumped/finetune_de_hsb_mlm_tlm_full-vocab/40000818/checkpoint.pth,${NMT_EXP_DIR}/dumped/finetune_de_hsb_mlm_tlm_full-vocab/40000818/checkpoint.pth" \
--data_path "${NMT_DATA_DIR}/processed/" \
--lgs "ar-bg-de-el-en-es-fr-hi-ru-sw-th-tr-ur-vi-zh-hsb" \
--ae_steps "de,hsb" \
--lambda_ae '0:1,100000:0.1,300000:0' \
--bt_steps "de-hsb-de,hsb-de-hsb" \
--lambda_bt '0:1,100000:0.1,300000:0' \
--mt_steps "${MT_STEPS}" \
--lambda_mt '0:1,100000:0.1,300000:0' \
--rabt_steps "${RABT_STEPS}" \
--lambda_rabt '0:1,100000:0.1,300000:0' \
--xbt_steps "${XBT_STEPS}" \
--lambda_xbt '0:1,100000:0.1,300000:0' \
--log_int 1000 \
--epsilon 0.1 \
--word_shuffle 3 \
--word_dropout 0.1 \
--word_blank 0.1 \
--encoder_only false \
--emb_dim 1024 \
--n_layers 6 \
--n_heads 8 \
--dropout 0.5 \
--attention_dropout 0.1 \
--gelu_activation true \
--batch_size 8 \
--bptt 256 \
--max_len 200 \
--optimizer adam_inverse_sqrt,beta1=0.9,beta2=0.98,lr=0.0001 \
--epoch_size 20000 \
--eval_bleu true \
--stopping_criterion 'valid_de-hsb_mt_bleu,10' \
--validation_metrics 'valid_de-hsb_mt_bleu' \
--debug_slurm true \
--debug_train false \
--max_vocab 123709 \
--amp 1 \
--fp16 true \
--accumulate_gradients 8 \

# --tokens_per_batch 1000 \
# --master_port 10001 \

# --increase_vocab_for_lang de  \
# --increase_vocab_from_lang hsb \
# --max_vocab 108812 \ 
# --debug_slurm false \
# --lambda_xbt '0:1,100000:0.1,300000:0' \
# --tokens_per_batch 50 \




# --lambda_ae '0:1,100000:0.1,300000:0' \
# --stopping_criterion 'valid_de-hsb_mt_bleu,10' \
# --validation_metrics 'valid_de-hsb_mt_bleu' \
