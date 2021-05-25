#!/usr/bin/env bash 
export COMET_MODE=ONLINE
export COMET_API_KEY="ZVTkXN5kScnbV6H4uBBZ97Qyv"
export COMET_PROJECT_NAME='unsupMT'


# MT_STEPS="de-hsb,"
MT_STEPS=""
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
LIST=${LIST/%_}

# removing the MT parallel

echo "MT: " $MT_STEPS 
echo "RABT: " $RABT_STEPS 
echo "XBT: " $XBT_STEPS
echo "LIST: " $LIST

# MT_STEPS=""
# WE ARE TRAINING A DE-->HSB MODEL 
# exit


# export NGPU=2; python -m torch.distributed.launch --nproc_per_node=$NGPU train.py \
python ./train.py \
--exp_name "de_${LIST}_hsb" \
--dump_path ${NMT_EXP_DIR}/dumped/ \
--reload_model "${NMT_EXP_DIR}/dumped/finetune_de_hsb_mlm_full-vocab/40631027/best-valid_hsb_mlm_ppl.pth,${NMT_EXP_DIR}/dumped/finetune_de_hsb_mlm_full-vocab/40631027/best-valid_hsb_mlm_ppl.pth" \
--data_path "${NMT_DATA_DIR}/processed/" \
--lgs "ar-bg-de-el-en-es-fr-hi-ru-sw-th-tr-ur-vi-zh-hsb" \
--ae_steps "de,hsb" \
--lambda_ae '0:1,100000:0.1,300000:0' \
--bt_steps "de-hsb-de,hsb-de-hsb" \
--lambda_bt '1' \
--mt_steps "${MT_STEPS}" \
--lambda_mt '1' \
--rabt_steps "${RABT_STEPS}" \
--lambda_rabt '1' \
--xbt_steps "${XBT_STEPS}" \
--lambda_xbt '1' \
--log_int 1000 \
--epsilon 0.1 \
--word_shuffle 3 \
--word_dropout 0.1 \
--word_blank 0.1 \
--encoder_only false \
--emb_dim 1024 \
--n_layers 12 \
--n_heads 16 \
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
--debug_slurm true \
--debug_train false \
--max_vocab 123709 \
--amp 1 \
--fp16 true \
--accumulate_gradients 4 \
--beam_size 5 \
--use_pretrained_lang_emb \
# --master_port 10001 \
# --lgs "de-hsb-${LIST}" \
# --tokens_per_batch 1000 \


