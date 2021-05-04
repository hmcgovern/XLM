#!/usr/bin/env bash 
export COMET_MODE=ONLINE
export COMET_API_KEY="ZVTkXN5kScnbV6H4uBBZ97Qyv"
export COMET_PROJECT_NAME='finetune-de-hsb'


# ./get-data-nmt.sh --src de --tgt hsb --reload_codes codes_xnli_15 --reload_vocab vocab_xnli_15

# export NGPU=4; python -m torch.distributed.launch --nproc_per_node=$NGPU train.py \

python ./train.py \
--exp_name finetune_de_hsb_mlm              \
--debug_train false                          \
--debug_slurm true                          \
--dump_path $NMT_EXP_DIR/dumped/            \
--reload_model 'mlm_tlm_xnli15_1024.pth'    \
--data_path $NMT_DATA_DIR/exp/hsb-de-8k     \
--mlm_steps 'de,hsb'                        \
--lgs "ar-bg-de-el-en-es-fr-hi-ru-sw-th-tr-ur-vi-zh-hsb" \
--use_lang_emb false                        \
--emb_dim 1024                              \
--n_layers 6                                \
--n_heads 8                                 \
--dropout 0.1                               \
--attention_dropout 0.1                     \
--gelu_activation true                      \
--batch_size 32                             \
--bptt 256                                  \
--optimizer adam,lr=0.0001                  \
--epoch_size 20000                          \
--increase_vocab_by 6257                    \
--validation_metrics valid_hsb_mlm_ppl      \
--stopping_criterion valid_hsb_mlm_ppl,10   

# --max_vocab 101681                          \