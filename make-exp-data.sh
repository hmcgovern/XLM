#!/usr/bin/env bash

src=en
ref=zh
tgt=de

OUTPATH=${NMT_DATA_DIR}/exp/${src}_${ref}_${tgt}
mkdir -p $OUTPATH

cp ${NMT_DATA_DIR}/processed/${SRC}/*.pth $OUTPATH
cp ${NMT_DATA_DIR}/processed/${REF}/*.pth $OUTPATH
cp ${NMT_DATA_DIR}/processed/${TGT}/*.pth $OUTPATH

# caveat, the naming convention might be reversed! add that nuance
# there's parallel data btw the src and ref, copy that over as well
if [ $src < $ref ]; then
    cp ${NMT_DATA_DIR}/processed/${src}-${ref}/*.pth $OUTPATH
else
    cp ${NMT_DATA_DIR}/processed/${ref}-${src}/*.pth $OUTPATH
fi

# and finally, parallel evaluation data between the src and tgt
if [ $src < $tgt ]; then
    cp ${NMT_DATA_DIR}/processed/${src}-${tgt}/*.pth $OUTPATH
else
    cp ${NMT_DATA_DIR}/processed/${tgt}-${src}/*.pth $OUTPATH
fi