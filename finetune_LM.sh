#!/usr/bin/env bash 
export COMET_MODE=ONLINE
export COMET_API_KEY="ZVTkXN5kScnbV6H4uBBZ97Qyv"
export COMET_PROJECT_NAME='finetune-de-hsb'

export PATH=/home/hem52/.conda/envs/nmt/bin:$PATH


# export NGPU=2; python -m torch.distributed.launch --nproc_per_node=$NGPU train.py \
python ./train.py \
--exp_name finetune_de_hsb_mlm              \
--debug_train false                          \
--dump_path $NMT_EXP_DIR/dumped/            \
--reload_model 'mlm_tlm_xnli15_1024.pth'    \
--data_path $NMT_DATA_DIR/exp/hsb-de        \
--lgs 'de-hsb'                              \
--mlm_steps 'de,hsb'                        \
--emb_dim 1024                              \
--n_layers 6                                \
--n_heads 8                                 \
--dropout 0.1                               \
--attention_dropout 0.1                     \
--gelu_activation true                      \
--batch_size 32                             \
--bptt 256                                  \
--optimizer adam,lr=0.0001                  \
--epoch_size 50000                          \
--validation_metrics valid_hsb_mlm_ppl      \
--stopping_criterion valid_hsb_mlm_ppl,3   \
--increase_vocab_for_lang de                \
--increase_vocab_from_lang hsb              \
--use_adapters true                         \
--max_vocab 167021                          \
--use_lang_emb false                        \
--adapter_size 256                          \
--increase_vocab_by 72021 #(see ./data/mk-en/vocab.mk-en-ext-by-$NUMBER)
# had to get max_vocab to 95000 + increase amount (72021)
# --epoch_size 50000                          \