#!/bin/sh -f 
######################################################################
# Compiles Elmer on NYE and BUDD.
#
# Created date: March 3, 2009
#               Version alpha.
#
# Modified date:
#               March 9, 2009.
#               Add conditions tests if some directories exist.
#               Remoded hard coded values for options, reads from 
#               INITIALIZE.val.
#               Version 1.0.
# Author: Hakime Seddik
# Institute of Low Tenperature Science, Hokkaido University.
######################################################################

ROOT_DIRECTORY="elmerdev"
ROOT_DEBUG_DIRECTORY="elmerdbg"
SOURCE_DIRECTORY="elmerfem"

BIN="bin"
LIB="lib"
INCLUDE="include"
SHARE="share"

cd /opt

#Options:

# 0 if compiling from already available SVN revision
GETNEWSVN=$(cat INITIALIZE.val | grep "GETNEWSVN" | awk -F":" '{print $2}')
#####################################################################

if test -d $ROOT_DIRECTORY ; then

cd /opt/elmerdev 
echo "Do ls #########"
ls
if test -d $BIN ; then
rm -rf bin
fi

if test -d $LIB ; then
rm -rf lib 
fi

if test -d $INCLUDE ; then
rm -rf include 
fi

if test -d $SHARE ; then
rm -rf share
fi

if test $GETNEWSVN -eq 1 ; then
if test -d $SOURCE_DIRECTORY ; then
rm -rf elmerfem
fi
fi
echo "Do ls #########"
ls
echo "###"
else
echo "No original elmer directry. Creates one."
mkdir elmerdev
cd elmerdev

fi

if test $GETNEWSVN -eq 1 ; then
SVN=$(cat /opt/REVISION.val)
if test $SVN -eq 0 ; then
svn co https://elmerfem.svn.sourceforge.net/svnroot/elmerfem elmerfem
SVN=$(svn info  https://elmerfem.svn.sourceforge.net/svnroot/elmerfem | grep "Revision" | awk -F":" '{print $2}')
echo "Last SVN revision $SVN will be compiled"
else 
echo "SVN revision $SVN will be compiled"
svn -r $SVN co https://elmerfem.svn.sourceforge.net/svnroot/elmerfem elmerfem
fi
else
echo "Use already available SVN revision"
fi

#The compiler wrapper scripts
export CC=gcc
export CXX=g++
export FC=gfortran
export F77=gfortran

#the compiler flags
export CFLAGS="-O5 -ftree-vectorize"
export CXXFLAGS="-O5 -ftree-vectorize"
export FCFLAGS="-O5 -ftree-vectorize -funroll-loops"
export F77FLAGS="-O5 -ftree-vectorize -funroll-loops"
export FFLAGS="-O5 -ftree-vectorize -funroll-loops"

#paths
export ELMER_HOME="/opt/elmerdev"

cd elmerfem/trunk

# modules
modules="matc umfpack mathlibs elmergrid meshgen2d eio hutiter fem post" 
for m in $modules; do
  cd $m
   make distclean
  ./configure --prefix=$ELMER_HOME
  make
  make install
  cd .. 
done

if test $GETNEWSVN -eq 1 ; then
cd /opt/elmerdev
cp -f /opt/README32bits .

echo "Build compiled from trunk revision $SVN" > README32bits
echo "Number of test failures:" >> README32bits
echo "Running solver tests"
cd elmerfem/trunk/fem 
make check >> /opt/elmerdev/README32bits
cat /opt/elmerdev/README32bits
fi

cd /opt/
rm -f REVISION.val
rm -f README32bits
rm -f INITIALIZE.val

echo "#############################################"
echo "Compilation completed. Have fun!!! "
echo "#############################################"

rm -f build-elmer32bits.sh 

#exit the host
exit
