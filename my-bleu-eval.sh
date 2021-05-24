hyp=$1
ref=$2
lg=$3

TOOLS_PATH=${XLM_REPO_DIR}/tools
DETOKENIZER=${TOOLS_PATH}/detokenize.sh

for file in $hyp $ref; do
    eval "cat $file | $DETOKENIZER $lg > $file.detok"
    echo "$file.detok"
done
