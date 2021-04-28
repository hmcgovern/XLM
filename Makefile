.PHONY: clean data lint requirements de-hsb-finetune # sync_data_to_s3 sync_data_from_s3

#################################################################################
# GLOBALS                                                                       #
#################################################################################

PROJECT_DIR := $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
# BUCKET = [OPTIONAL] your-bucket-for-syncing-data (do not include 's3://')
PROFILE = default
PROJECT_NAME = low-resource-mt
PYTHON_INTERPRETER = python
# PYTHON_INTERPRETER = ~/.conda/envs/nmt/bin/python

### my globals ###
# use the existing DATA_DIR value if it's set, otherwise MY user default
DATA_DIR=$(NMT_DATA_DIR:/rds/user/hem52/hpc-work/data)

ifeq (,$(shell which conda))
HAS_CONDA=False
else
HAS_CONDA=True
endif

#################################################################################
# COMMANDS                                                                      #
#################################################################################

## Install Python Dependencies
requirements: test_environment
	$(PYTHON_INTERPRETER) -m pip install -U pip setuptools wheel
	$(PYTHON_INTERPRETER) -m pip install -r requirements.txt

## Make Dataset
data: requirements
	# NOTE: currently is a dud bc I've downloaded data and it didn't need to be separated or cleaned
	OUTPUT_DIR=$(DATA_DIR)/processed/
	SRC_DIR=$(DATA_DIR)/raw/train.hsb-de.de
	TGT_DIR=$(DATA_DIR)/raw/train.hsb-de.hsb
	$(PYTHON_INTERPRETER) src/data/make_dataset.py $(SRC_DIR) $(TGT_DIR) $(OUTPUT_DIR)

## Delete all compiled Python files
clean:
	# find . -type f -name "*.py[co]" -delete
	# find . -type d -name "__pycache__" -delete
	find . -type f -name "all.*" -delete
	find . -type f -name "all.*.tok" -delete
	rm -r /$(XLM_REPO_DIR)/data/processed/de-en/

## Lint using flake8
lint:
	flake8 src

## Upload Data to S3
# sync_data_to_s3:
# ifeq (default,$(PROFILE))
# 	aws s3 sync data/ s3://$(BUCKET)/data/
# else
# 	aws s3 sync data/ s3://$(BUCKET)/data/ --profile $(PROFILE)
# endif

# ## Download Data from S3
# sync_data_from_s3:
# ifeq (default,$(PROFILE))
# 	aws s3 sync s3://$(BUCKET)/data/ data/
# else
# 	aws s3 sync s3://$(BUCKET)/data/ data/ --profile $(PROFILE)
# endif

## Set up python interpreter environment
create_environment:
ifeq (True,$(HAS_CONDA))
		@echo ">>> Detected conda, creating conda environment."
ifeq (3,$(findstring 3,$(PYTHON_INTERPRETER)))
	conda create --name $(PROJECT_NAME) python=3
else
	conda create --name $(PROJECT_NAME) python=2.7
endif
		@echo ">>> New conda env created. Activate with:\nsource activate $(PROJECT_NAME)"
else
	$(PYTHON_INTERPRETER) -m pip install -q virtualenv virtualenvwrapper
	@echo ">>> Installing virtualenvwrapper if not already installed.\nMake sure the following lines are in shell startup file\n\
	export WORKON_HOME=$$HOME/.virtualenvs\nexport PROJECT_HOME=$$HOME/Devel\nsource /usr/local/bin/virtualenvwrapper.sh\n"
	@bash -c "source `which virtualenvwrapper.sh`;mkvirtualenv $(PROJECT_NAME) --python=$(PYTHON_INTERPRETER)"
	@echo ">>> New virtualenv created. Activate with:\nworkon $(PROJECT_NAME)"
endif

## Test python environment is setup correctly
test_environment:
	$(PYTHON_INTERPRETER) test_environment.py

#################################################################################
# PROJECT RULES                                                                 #
#################################################################################

## download, tokenize, encode, and binarize data from the web internets
# preprocess: #test.de-en.de test.de-en.en #etc
# 	@bash XLM/src/scripts/preprocess-data.sh

en-de: mlm_ende_1024.pth codes_ende vocab_ende
	@bash get-data-nmt.sh --src de --tgt en --reload_codes codes_ende --reload_vocab vocab_ende

en-ro: mlm_enro_1024.pth codes_enro vocab_enro
	@bash get-data-nmt.sh --src en --tgt ro --reload_codes codes_enro --reload_vocab vocab_enro

de-hsb-finetune: 
	# rm -r $(NMT_DATA_DIR)/exp/hsb-de 
	./get-data-xnli-mt.sh de 16000
	./get_data_and_preprocess.sh --src de --tgt hsb --bpe 16000
	# @bash ./finetune_LM.sh

finetune:
	./finetune_LM.sh

de-hsb-nmt:
	@bash get-data-nmt.sh --src de --tgt hsb --reload_codes codes_xnli_15 --reload_vocab $(NMT_DATA_DIR)/exp/hsb-de/vocab.hsb-de-ext-by-28311
de-bg-hsb:
	@bash get-data-para.sh --pair de-bg --reload_codes codes_xnli_15 --reload_vocab $(NMT_DATA_DIR)/exp/hsb-de/vocab.hsb-de-ext-by-28311
	@bash get-data-nmt.sh --src bg --tgt de --reload_codes codes_xnli_15 --reload_vocab $(NMT_DATA_DIR)/exp/hsb-de/vocab.hsb-de-ext-by-28311 
de-ru-hsb:
	@bash get-data-para.sh --pair de-ru --reload_codes codes_xnli_15 --reload_vocab $(NMT_DATA_DIR)/exp/hsb-de/vocab.hsb-de-ext-by-28311
	@bash get-data-nmt.sh --src de --tgt ru --reload_codes codes_xnli_15 --reload_vocab $(NMT_DATA_DIR)/exp/hsb-de/vocab.hsb-de-ext-by-28311 
de-fr-hsb:
	@bash get-data-para.sh --pair de-fr --reload_codes codes_xnli_15 --reload_vocab $(NMT_DATA_DIR)/exp/hsb-de/vocab.hsb-de-ext-by-28311
	@bash get-data-nmt.sh --src de --tgt fr --reload_codes codes_xnli_15 --reload_vocab $(NMT_DATA_DIR)/exp/hsb-de/vocab.hsb-de-ext-by-28311
de-ar-hsb:
	@bash get-data-para.sh --pair de-ar --reload_codes codes_xnli_15 --reload_vocab $(NMT_DATA_DIR)/exp/hsb-de/vocab.hsb-de-ext-by-28311
	@bash get-data-nmt.sh --src ar --tgt de --reload_codes codes_xnli_15 --reload_vocab $(NMT_DATA_DIR)/exp/hsb-de/vocab.hsb-de-ext-by-28311 

# NOTE: these can be condensed with rules, will be useful when there's a lot of them
mlm_enro_1024.pth:
	wget -c https://dl.fbaipublicfiles.com/XLM/mlm_enro_1024.pth
codes_enfr:
	wget -c https://dl.fbaipublicfiles.com/XLM/codes_enro

vocab_enro:
	wget -c https://dl.fbaipublicfiles.com/XLM/vocab_enro

mlm_ende_1024.pth:
	wget -c https://dl.fbaipublicfiles.com/XLM/mlm_ende_1024.pth

codes_ende:
	wget -c https://dl.fbaipublicfiles.com/XLM/codes_ende

vocab_ende:
	wget -c https://dl.fbaipublicfiles.com/XLM/vocab_ende

mlm_xnli17_1280.pth:
	cd ${NMT_EXP_DIR}/models & wget -c https://dl.fbaipublicfiles.com/XLM/mlm_17_1280.pth

codes_xnli_17:
	cd ${NMT_EXP_DIR}/models & wget -c https://dl.fbaipublicfiles.com/XLM/codes_xnli_17

vocab_xnli_17:
	cd ${NMT_EXP_DIR}/models & wget -c https://dl.fbaipublicfiles.com/XLM/vocab_xnli_17

	# for lg in ar de en ; do \
  	# 	./get-data-wiki.sh $$lg ${NMT_EXP_DIR}/data/wiki ; \
	# done

download-runmt-data: mlm_xnli17_1280.pth codes_xnli_17 vocab_xnli_17
	@bash get-data-nmt.sh --src en --tgt fr --reload_codes codes_xnli_17 --reload_vocab vocab_xnli_17
	@bash get-data-nmt.sh --src de --tgt en --reload_codes codes_xnli_17 --reload_vocab vocab_xnli_17

	for pair in en-fr ; do \
		./get-data-para.sh $$pair ./data/runmt_para ; \
		./prepare-multi-data-nmt.sh $$pair ; \
	done

clean_para:
	rm -r ${NMT_DATA_DIR}/processed/en-fr/para/
	rm ${NMT_DATA_DIR}/processed/en-fr/codes
	rm ${NMT_DATA_DIR}/processed/en-fr/vocab.en-fr
	rm ${NMT_DATA_DIR}/processed/en-fr/vocab.en
	rm ${NMT_DATA_DIR}/processed/en-fr/vocab.fr

	rm -r ${NMT_DATA_DIR}/processed/en-ro/para/
	rm ${NMT_DATA_DIR}/processed/en-ro/codes
	rm ${NMT_DATA_DIR}/processed/en-ro/vocab.en-ro
	rm ${NMT_DATA_DIR}/processed/en-ro/vocab.en
	rm ${NMT_DATA_DIR}/processed/en-ro/vocab.ro

	rm -r ${NMT_DATA_DIR}/processed/de-en/para/
	rm ${NMT_DATA_DIR}/processed/de-en/codes
	rm ${NMT_DATA_DIR}/processed/de-en/vocab.de-en
	rm ${NMT_DATA_DIR}/processed/de-en/vocab.de
	rm ${NMT_DATA_DIR}/processed/de-en/vocab.en
	
	rm -r ${NMT_DATA_DIR}/processed/en-zh/para/
	rm ${NMT_DATA_DIR}/processed/en-zh/codes
	rm ${NMT_DATA_DIR}/processed/en-zh/vocab.en-zh
	rm ${NMT_DATA_DIR}/processed/en-zh/vocab.en
	rm ${NMT_DATA_DIR}/processed/en-zh/vocab.zh

train: #get_pretrained
	@bash train.sh 
	#$(PROJECT_NAME) 

train_runmt:
	@bash train_ref_agreement.sh


#################################################################################
# Self Documenting Commands                                                     #
#################################################################################

.DEFAULT_GOAL := help

# Inspired by <http://marmelab.com/blog/2016/02/29/auto-documented-makefile.html>
# sed script explained:
# /^##/:
# 	* save line in hold space
# 	* purge line
# 	* Loop:
# 		* append newline + line to hold space
# 		* go to next line
# 		* if line starts with doc comment, strip comment character off and loop
# 	* remove target prerequisites
# 	* append hold space (+ newline) to line
# 	* replace newline plus comments by `---`
# 	* print line
# Separate expressions are necessary because labels cannot be delimited by
# semicolon; see <http://stackoverflow.com/a/11799865/1968>
.PHONY: help
help:
	@echo "$$(tput bold)Available rules:$$(tput sgr0)"
	@echo
	@sed -n -e "/^## / { \
		h; \
		s/.*//; \
		:doc" \
		-e "H; \
		n; \
		s/^## //; \
		t doc" \
		-e "s/:.*//; \
		G; \
		s/\\n## /---/; \
		s/\\n/ /g; \
		p; \
	}" ${MAKEFILE_LIST} \
	| LC_ALL='C' sort --ignore-case \
	| awk -F '---' \
		-v ncol=$$(tput cols) \
		-v indent=19 \
		-v col_on="$$(tput setaf 6)" \
		-v col_off="$$(tput sgr0)" \
	'{ \
		printf "%s%*s%s ", col_on, -indent, $$1, col_off; \
		n = split($$2, words, " "); \
		line_length = ncol - indent; \
		for (i = 1; i <= n; i++) { \
			line_length -= length(words[i]) + 1; \
			if (line_length <= 0) { \
				line_length = ncol - indent - length(words[i]) - 1; \
				printf "\n%*s ", -indent, " "; \
			} \
			printf "%s ", words[i]; \
		} \
		printf "\n"; \
	}' \
	| more $(shell test $(shell uname) = Darwin && echo '--no-init --raw-control-chars')
