# Script to install pcl and most of its dependencies.
# Written for Ubuntu 13.04 (64 bit)
# with CUDA 5.5 already installed into /usr/local/cuda/ and:
#   export PATH=/usr/local/cuda/bin:$PATH
#   export CUDA_PATH=/usr/local/cuda
#   export LIBRARY_PATH=/usr/lib/nvidia-331:LIBRARY_PATH
#   export LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH

# Prerequisites: sudo apt-get install git build-essential cmake qt4-qmake qt4-dev-tools

# This script needs sudo for the OpenNI Sensor Xtion driver udev rules.

# You might want to adjust the make -j4 invocations to use more/less cores
# when compiling, but you should have around 1.5 GB RAM per core (C++ is insane).

# Where to install all sofware to
export PREFIX=/data/nh910/opt/pcl

# Some paths we jump back to a lot
export TOP=$PWD
export DEPS=$TOP/deps

# Stop at first error
set -e

mkdir -p $DEPS


# Eigen3

cd $DEPS
apt-get source libeigen3-dev
cd eigen3-*
mkdir -p build && cd build
cmake .. -DCMAKE_INSTALL_PREFIX=$PREFIX
make install -j4


# Flann

cd $DEPS
wget -c http://www.cs.ubc.ca/research/flann/uploads/FLANN/flann-1.8.4-src.zip
unzip flann-*.zip
cd flann-*/
mkdir -p build && cd build
cmake .. -DCMAKE_INSTALL_PREFIX=$PREFIX
make install -j4


# libusb

cd $DEPS
wget -c http://sourceforge.net/projects/libusb/files/libusb-1.0/libusb-1.0.9/libusb-1.0.9.tar.bz2
tar xaf libusb*.tar.bz2
cd libusb-*/
./configure --prefix=$PREFIX
make install -j4


# OpenNI

cd $DEPS
git clone https://github.com/OpenNI/OpenNI.git
cd OpenNI
cd Platform/Linux/CreateRedist
LDFLAGS=-L$PREFIX/lib CFLAGS=-I$PREFIX/include ./RedistMaker
# I haven't figured out yet how to install OpenNI into a prefix :(
# See https://github.com/OpenNI/OpenNI/issues/97
cd ../Redist/OpenNI-Bin-Dev-Linux-x64-v1.5.7.10
sudo ./install.sh  # installs niReg which is required for the Sensor driver installer


# OpenNI Sensor driver for Asus Xtion

cd $DEPS
git clone https://github.com/PrimeSense/Sensor.git
cd Sensor
cd Platform/Linux/CreateRedist
LDFLAGS="-L$PREFIX/lib -L$DEPS/OpenNI/Platform/Linux/Redist/OpenNI-Bin-Dev-Linux-x64-v1.5.7.10/Lib" CFLAGS="-I$PREFIX/include -I$DEPS/OpenNI/Include/" ./RedistMaker
cd ../Redist/Sensor-Bin-Linux-x64-v5.1.6.6/
sudo ./install.sh  # 1for the udev rules to allow writing to the camera device


# HDF5

cd $DEPS
apt-get source libhdf5-dev
cd hdf5-*/
./configure --enable-cxx --prefix=$PREFIX
# note that many options are disabled - maybe some of them may make it faster
make install -j4


# HDF4

cd $DEPS
apt-get source libhdf4-dev
cd libhdf4-*/
cd upstream
tar xaf HDF4*.tar.gz
cd HDF4*/
patch -p2 < ../../debian/patches/config  # use debian's patch to change g77 to gfortran
./configure --prefix=$PREFIX
make install -j4


# netcdf

cd $DEPS
apt-get source libnetcdf-dev
cd netcdf-*/
# netcdf's configure script doesn't seem to set include/lib paths from --prefix :(
LDFLAGS=-L$PREFIX/lib CPPFLAGS=-I$PREFIX/include ./configure --prefix=$PREFIX
make install -j4


# VTK

# VTK 6 is too new, get error io/src/vtk_lib_io.cpp:181:16: error: no member named 'SetInput'
# cd $DEPS
# wget -c http://www.vtk.org/files/release/6.1/VTK-6.1.0.tar.gz
# tar xaf VTK-6*.tar.gz
# cd VTK-*/
# mkdir -p build && cd build
# # From http://www.vtk.org/Wiki/VTK/Tutorials/QtSetup
# # needs QT4, so we need to tell it to use the older qmake explicitly
# cmake .. -DCMAKE_INSTALL_PREFIX=$PREFIX -DVTK_Group_Qt=ON -DQT_QMAKE_EXECUTABLE=qmake-qt4 -DBUILD_SHARED_LIBS=ON
# make install -j4  # might only work with -j1

cd $DEPS
wget -c http://www.vtk.org/files/release/5.10/vtk-5.10.1.tar.gz
tar xaf vtk-5*.tar.gz
cd VTK5*/
mkdir -p build && cd build
# From http://www.vtk.org/Wiki/VTK/Tutorials/QtSetup
# needs QT4, so we need to tell it to use the older qmake explicitly
cmake .. -DCMAKE_INSTALL_PREFIX=$PREFIX -DQT_QMAKE_EXECUTABLE=qmake-qt4 -DVTK_USE_QT=ON -DVTK_USE_GUISUPPORT=ON -DBUILD_SHARED_LIBS=ON
make install -j4


# PCL

cd $TOP
# git clone https://github.com/PointCloudLibrary/pcl.git
git clone -b fix-kinfu-build https://github.com/nh2/pcl.git  # fixes to make kinfu build
cd pcl
# Switch off QT5 - see bug https://github.com/PointCloudLibrary/pcl/issues/477
wget -c https://gist.github.com/nh2/8617701/raw/pcl-use-qt4-for-bug-477.patch
patch < pcl-use-qt4-for-bug-477.patch
mkdir -p build && cd build
# export CC=clang     # optional
# export CXX=clang++  # optional
# cmake .. -DCMAKE_INSTALL_PREFIX=$PREFIX -DCMAKE_BUILD_TYPE=Debug  # for debug build with O0
# cmake .. -DCMAKE_INSTALL_PREFIX=$PREFIX -DCMAKE_BUILD_TYPE=Debug -i  # for wizard mode to select targets (have not figured out yet which are required for kinfu / kinfu_large_scale)
# rm -rf *  # Note that you have to delete everything if you want to make significant changes to these CMAKE flags
cmake .. -DCMAKE_INSTALL_PREFIX=$PREFIX -DOPENNI_LIBRARY=$DEPS/OpenNI/Platform/Linux/Redist/OpenNI-Bin-Dev-Linux-x64-v1.5.7.10/Lib/libOpenNI.so -DOPENNI_INCLUDE_DIR=$DEPS/OpenNI/Platform/Linux/Redist/OpenNI-Bin-Dev-Linux-x64-v1.5.7.10/Include -DBUILD_visualization=ON -DBUILD_apps=ON -DBUILD_CUDA=ON -DBUILD_GPU=ON -DBUILD_gpu_kinfu=ON -DBUILD_gpu_kinfu_large_scale=ON -DCMAKE_BUILD_TYPE=Debug
make -j4
make install
