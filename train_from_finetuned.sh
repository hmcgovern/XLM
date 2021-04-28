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
# want to have this as a cli
for ref in en bg; do
    MT_STEPS+="de-${ref},"
    RABT_STEPS+="de-${ref}-hsb,${ref}-de-hsb,"
    XBT_STEPS+="de-hsb-${ref},${ref}-hsb-de,"
done

echo "MT" $MT_STEPS 
echo "RABT" $RABT_STEPS 
echo "XBT" $XBT_STEPS

# ref=$1
# WE ARE TRAINING A DE-->HSB MODEL 
# python ./train.py \
export NGPU=4; python -m torch.distributed.launch --nproc_per_node=$NGPU train.py \
--exp_name "unsupMT_de_${ref}_hsb" \
--dump_path ${NMT_EXP_DIR}/dumped/ \
--reload_model "${NMT_EXP_DIR}/dumped/finetune_de_hsb_mlm/38049037/best-valid_hsb_mlm_ppl.pth,${NMT_EXP_DIR}/dumped/finetune_de_hsb_mlm/38049037/best-valid_hsb_mlm_ppl.pth" \
--data_path "${NMT_DATA_DIR}/processed/" \
--lgs "ar-bg-de-el-en-es-fr-hi-ru-sw-th-tr-ur-vi-zh-hsb" \
--ae_steps "de,hsb" \
--lambda_ae '0:1,100000:0.1,300000:0' \
--bt_steps "de-hsb-de,hsb-de-hsb" \
--lambda_bt '0:1,100000:0.1,300000:0' \
--mt_steps "{MT_STEPS}" \
--lambda_mt '0:1,100000:0.1,300000:0' \
--rabt_steps "{RABT_STEPS}" \
--lambda_rabt '0:1,100000:0.1,300000:0' \
--xbt_steps "{XBT_STEPS}" \
--lambda_xbt '0:1,100000:0.1,300000:0' \
--log_int 20 \
--epsilon 0.1 \
--word_shuffle 3 \
--word_dropout 0.1 \
--word_blank 0.1 \
--lambda_rabt '0'
--encoder_only false \
--emb_dim 1024 \
--n_layers 6 \
--n_heads 8 \
--dropout 0.1 \
--attention_dropout 0.1 \
--gelu_activation true \
--batch_size 32 \
--bptt 256 \
--max_len 200 \
--optimizer adam_inverse_sqrt,beta1=0.9,beta2=0.98,lr=0.0001 \
--epoch_size 200000 \
--eval_bleu false \
--stopping_criterion 'valid_de-hsb_mt_bleu,10' \
--validation_metrics 'valid_de-hsb_mt_bleu' \
--debug_train true \
--debug_slurm true \
--max_vocab 123311 \
--amp 1 \
--fp16 true \
--increase_vocab_for_lang de  \
--increase_vocab_from_lang hsb \
--use_lang_emb true \
--accumulate_gradients 2 \
# --tokens_per_batch 500 \
# --lambda_ae '0:1,100000:0.1,300000:0' \