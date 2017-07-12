#!/bin/sh -f 
######################################################################
# Compiles Open MPI and HYPRE.
#
# Created date: March 3, 2009
#               Version alpha.
#
# Modified date:
#               March 9, 2009.
#               Add conditions tests if some directories exist.
#               Some minor code reorganization.
#               Version 1.0
#
#               January 29, 2013
#               Set the --libdir option for Open MPI and HYPRE configure to $ELMER_HOME/lib so that it
#               forces the installation of the libraries in "lib" and not "lib64".
#               This is required on Open SUSE 12.2 and later.
#               Version 1.01
#
# Author: Hakime Seddik
# Institute of Low Tenperature Science, Hokkaido University.
######################################################################

MPI_DIRECTORY="openmpi"
HYPRE_DIRECTORY="hypre"
SOURCE="source"

cd /opt

#IFORT=$(cat INITIALIZE.val | grep "IFORT" | awk -F"->" '{print $2}')
#GFORTRAN=$(cat INITIALIZE.val | grep "GFORTRAN" | awk -F"->" '{print $2}')

if test -d $MPI_DIRECTORY ; then
rm -rf openmpi
fi

if test -d $HYPRE_DIRECTORY ; then
rm -rf hypre
fi

OPENMPI=$(cat MPI_HYPRE_VER.val | grep "OPENMPI" | awk -F":" '{print $2}')
HYPRE=$(cat MPI_HYPRE_VER.val | grep "HYPRE" | awk -F":" '{print $2}')

tar -xvzf $OPENMPI.tar.gz
tar -xvzf $HYPRE.tar.gz

mv $OPENMPI openmpi
mv $HYPRE hypre

rm -f $OPENMPI.tar.gz
rm -f $HYPRE.tar.gz

if test -d $SOURCE ; then
cd source
echo "Do ls #####"
ls
else 
echo "Directory Source does not exist"
exit -1
fi

if test -d $MPI_DIRECTORY ; then
rm -rf openmpi
fi

if test -d $HYPRE_DIRECTORY ; then
rm -rf hypre
fi

mv /opt/openmpi .
mv /opt/hypre .

echo "Do ls ###"
ls

cd openmpi


#echo "Compiling with ifort"
#export PATH="/usr/riron/intel/fc/bin:$PATH"
#export LD_LIBRARY_PATH="/usr/riron/intel/fc/lib:$LD_LIBRARY_PATH"
#export INTEL_LICENSE_FILE="/usr/riron/intel/etc"

#./configure --prefix=/opt/openmpi CC=gcc CXX=g++ F77=ifort F90=ifort FC=ifort CFLAGS='-O5 -ftree-vectorize' FFLAGS='-O3 -unroll' CXXFLAGS='-O5 -ftree-vectorize' FCFLAGS='-O3 -unroll' --enable-static && make all install

#echo "Compiling with gfortran"
./configure --prefix=/opt/openmpi CC=gcc CXX=g++ F77=gfortran F90=gfortran FC=gfortran CFLAGS='-O5 -ftree-vectorize' FFLAGS='-O5 -ftree-vectorize -funroll-loops' CXXFLAGS='-O5 -ftree-vectorize' FCFLAGS='-O5 -ftree-vectorize -funroll-loops' --enable-static --libdir=/opt/openmpi/lib && make all install

cd /opt/source/hypre/src

export MPI_HOME="/opt/openmpi"
export PATH="$MPI_HOME/bin:$PATH"
export LD_LIBRARY_PATH="$MPI_HOME/lib:$LD_LIBRARY_PATH"


export CC="mpicc -fPIC"
export CXX="mpic++ -fPIC"
export FC="mpif90 -fPIC"
export F77="mpif90 -fPIC"

./configure --prefix=/opt/hypre --with-MPI-include=$MPI_HOME/include --with-MPI-lib-dirs=$MPI_HOME/lib --libdir=/opt/hypre/lib && make install

echo "#########################"
echo "Compilation completed"
echo "#########################"

cd /opt
rm -f MPI_HYPRE_VER.val
rm -f build_MPI_HYPRE.sh 
rm -f INITIALIZE.val

# Exit Host
exit

