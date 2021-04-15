module unload cuda/10.0 cudnn/7.5_cuda-10.0
module load python/3.6 cuda/10.2 cudnn/7.6_cuda-10.2

git clone https://github.com/NVIDIA/apex
cd apex
pip install -v --disable-pip-version-check --no-cache-dir --global-option="--cpp_ext" --global-option="--cuda_ext" ./
