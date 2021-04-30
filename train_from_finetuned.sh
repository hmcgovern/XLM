#!/usr/bin/env bash 
export COMET_MODE=ONLINE
export COMET_API_KEY="ZVTkXN5kScnbV6H4uBBZ97Qyv"
export COMET_PROJECT_NAME='unsupMT'

# # parse input langs
# #
# # Read arguments
# #
# POSITIONAL=()
# while [[ $# -gt 0 ]]
# do
# key="$1"
# case $key in
#   --src)
#     SRC="$2"; shift 2;;
#   --tgt)
#     TGT="$2"; shift 2;;
#   --ref)
#     REF="$2"; shift 2;;
#   *)
#   POSITIONAL+=("$1")
#   shift
#   ;;
# esac
# done
# set -- "${POSITIONAL[@]}"

#just wrap this in a loop, maybe some logic to parse rabt/xbt etc steps until 
MT_STEPS=""
RABT_STEPS=""
XBT_STEPS=""

for ref in $@; do
    MT_STEPS+="de-${ref},"
    RABT_STEPS+="de-${ref}-hsb,${ref}-de-hsb,"
    XBT_STEPS+="de-hsb-${ref},${ref}-hsb-de,"
done

# need to prune the trailing comma
# echo "MT" $MT_STEPS 
# echo "RABT" $RABT_STEPS 
# echo "XBT" $XBT_STEPS

MT_STEPS=${MT_STEPS/%,}
RABT_STEPS=${RABT_STEPS/%,}
XBT_STEPS=${XBT_STEPS/%,}
# need to prune the trailing comma
echo "MT: " $MT_STEPS 
echo "RABT: " $RABT_STEPS 
echo "XBT: " $XBT_STEPS

# exit

# WE ARE TRAINING A DE-->HSB MODEL 

# export NGPU=2; python -m torch.distributed.launch --nproc_per_node=$NGPU train.py \
python ./train.py \
--exp_name "de_${ref}_hsb_16k" \
--dump_path ${NMT_EXP_DIR}/dumped/ \
--reload_model "${NMT_EXP_DIR}/dumped/finetune_de_hsb_mlm/38967777/best-valid_hsb_mlm_ppl.pth,${NMT_EXP_DIR}/dumped/finetune_de_hsb_mlm/38967777/best-valid_hsb_mlm_ppl.pth" \
--data_path "${NMT_DATA_DIR}/processed/" \
--lgs "ar-bg-de-el-en-es-fr-hi-ru-sw-th-tr-ur-vi-zh-hsb" \
--ae_steps "de,hsb" \
--lambda_ae '0:1,100000:0.1,300000:0' \
--bt_steps "de-hsb-de,hsb-de-hsb" \
--mt_steps "{MT_STEPS}" \
--rabt_steps "{RABT_STEPS}" \
--xbt_steps "{XBT_STEPS}" \
--log_int 1000 \
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
--batch_size 8 \
--bptt 256 \
--max_len 200 \
--optimizer adam_inverse_sqrt,beta1=0.9,beta2=0.98,lr=0.0001 \
--epoch_size 200000 \
--eval_bleu false \
--stopping_criterion 'valid_de-hsb_mt_bleu,10' \
--validation_metrics 'valid_de-hsb_mt_bleu' \
--max_vocab 108812 \ 
--increase_vocab_for_lang de  \
--increase_vocab_from_lang hsb \
--use_lang_emb true \
--amp 1 \
--fp16 true \
--accumulate_gradients 4 \
--debug_train false \
--master_port 10001 \

# --debug_slurm false \
# --lambda_xbt '0:1,100000:0.1,300000:0' \
# --tokens_per_batch 50 \
# --lambda_ae '0:1,100000:0.1,300000:0' \
# --lambda_rabt '0:1,100000:0.1,300000:0' \
# --lambda_mt '0:1,100000:0.1,300000:0' \
# --lambda_bt '0:1,100000:0.1,300000:0' \
