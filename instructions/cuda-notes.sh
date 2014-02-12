export PATH=/usr/local/cuda/bin:$PATH
export CUDA_PATH=/usr/local/cuda
export LIBRARY_PATH=/usr/lib/nvidia-331:LIBRARY_PATH
# export LIBRARY_PATH=/usr/lib/nvidia-319:LIBRARY_PATH
export LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH


export PATH=/data/nh910/opt/ghc-7.6.3/bin:$PATH
export LD_LIBRARY_PATH=/data/nh910/opt/ghc-7.6.3/lib

cabal install cabal-install
# set up PATH
cabal install -j4 c2hs
cabal install -j4 accelerate-cuda



# For installing cuda
sudo apt-get install build-essential libglu1-mesa-dev libx11-dev libxi-dev libxmu-dev


wget http://developer.download.nvidia.com/compute/cuda/5_5/rel/installers/cuda_5.5.22_linux_64.run
./cuda_5.5.22_linux_64.run -extract=$PWD/cuda-installer
cd cuda-installer
sudo ./cuda-linux64-rel-5.5.22-16488124.run -noprompt
