#!/bin/sh -f
######################################################################
# Compiles Elmer on GLEN, MARVIN and ZAPHOD.
#
# Created date: March 3, 2009
#               Version alpha.
#
# Modified date:
#               March 9, 2009.
#               Add conditions tests if some directories exist.
#               Removed hard coded values for options, reads from 
#               INITIALIZE.val.
#               Version 1.0
#               
#               April 3, 2009
#               Change separator in INITIALIZE.val for MUMPS  and SUPERLU
#               from : to ->.
#               Version 1.01
#
#               August 21, 2009
#               Add a keyword for MUMPS directory location in INITIALIZE.val 
#               Version 1.02
#
#               December 7, 2009
#               Fix a bug where not compiling MUMPS would end up not having the directory location of MUMPS
#               if an existing compiled version is neverthless linked to binaries.
#               Version 1.03
#
#               January 29, 2013
#               - Set the --libdir option for elmer configure to $ELMER_HOME/lib so that it forces the installation
#                 of the libraries in "lib" and not "lib64". This is required on Open SUSE 12.2 and later.
#               - Add -lstdc++ to LDFLAGS to avoid an error where the C++ standard library is not found (this happens
#                 only when compiling the debug version of elmer). This is apprently due to some changes in the recent
#                 versions of ld when linking required objects/libraries through intermediate objects/libraries
#                 (http://fedoraproject.org/wiki/UnderstandingDSOLinkChange).
#               Version 1.04
#
# Author: Hakime Seddik
# Institute of Low Tenperature Science, Hokkaido University.
######################################################################

ROOT_DIRECTORY="elmerdev"
ROOT_DEBUG_DIRECTORY="elmerdbg"
SOURCE_DIRECTORY="trunk"

BIN="bin"
LIB="lib"
INCLUDE="include"
SHARE="share"

cd /opt

#Options:

# 0 if compiling from already available SVN revision
GETNEWSVN=$(cat INITIALIZE.val | grep "GETNEWSVN" | awk -F":" '{print $2}')

#Which numerical library we compile
MUMPS=$(cat INITIALIZE.val | grep "MUMPS" | awk -F"->" '{print $2}')
SUPERLU=$(cat INITIALIZE.val | grep "SUPERLU" | awk -F"->" '{print $2}')

#Which numerical library we link to ElmerSolver
USEMUMPS=$(cat INITIALIZE.val | grep "USEMUMPS" | awk -F":" '{print $2}')
USESUPERLU=$(cat INITIALIZE.val | grep "USESUPERLU" | awk -F":" '{print $2}')
USEPARDISO=$(cat INITIALIZE.val | grep "USEPARDISO" | awk -F":" '{print $2}')

#Do we do tests for some of the numerical libraries?
TESTBLACS=$(cat INITIALIZE.val | grep "TESTBLACS" | awk -F":" '{print $2}')
TESTSCALAPACK=$(cat INITIALIZE.val | grep "TESTSCALAPACK" | awk -F":" '{print $2}')
TESTPARMETIS=$(cat INITIALIZE.val | grep "TESTPARMETIS" | awk -F":" '{print $2}')

#Do we compile a debug build
DEBUG_BUILD=$(cat INITIALIZE.val | grep "DEBUG_BUILD" | awk -F":" '{print $2}')

#Which compiler we use
#IFORT=$(cat INITIALIZE.val | grep "IFORT" | awk -F"->" '{print $2}')
#GFORTRAN=$(cat INITIALIZE.val | grep "GFORTRAN" | awk -F"->" '{print $2}')
#######################################################################

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
rm -rf trunk
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
svn co svn://svn.code.sf.net/p/elmerfem/code/trunk/
SVN=$(svn info  svn://svn.code.sf.net/p/elmerfem/code/trunk/ | grep "Revision" | awk -F":" '{print $2}')
echo "Last SVN revision $SVN will be compiled"
else 
echo "SVN revision $SVN will be compiled"
svn -r $SVN co svn://svn.code.sf.net/p/elmerfem/code/trunk/
fi
else
echo "Use already available SVN revision"
fi

#the compiler MPI wrappers
export CC=mpicc
export CXX=mpic++
export FC=mpif90
export F77=mpif90

#the compiler flags 

#export CFLAGS="-I/opt/hypre/include -O5 -ftree-vectorize -march=x86-64"
#export CXXFLAGS="-I/opt/hypre/include -O5 -ftree-vectorize -march=x86-64"
#export FCFLAGS="-I/opt/hypre/include -O3 -unroll"
#export F77FLAGS="-I/opt/hypre/include -O3 -unroll"
#export FFLAGS="-I/opt/hypre/include -O3 -unroll"
#export F90FLAGS="-I/opt/hypre/include -O3 -unroll"

export CFLAGS="-I/opt/hypre/include -O3 -ftree-vectorize -march=x86-64"
export CXXFLAGS="-I/opt/hypre/include -O3 -ftree-vectorize -march=x86-64"
export FCFLAGS="-I/opt/hypre/include -O3 -ftree-vectorize -funroll-loops -march=x86-64"
export F77FLAGS="-I/opt/hypre/include -O3 -ftree-vectorize -funroll-loops -march=x86-64"
export FFLAGS="-I/opt/hypre/include -O3 -ftree-vectorize -funroll-loops -march=x86-64"
export F90FLAGS="-I/opt/hypre/include -O3 -ftree-vectorize -funroll-loops -march=x86-64"

#paths
export ELMER_HOME="/opt/elmerdev"
export MPI_HOME="/opt/openmpi"
export HYPRE_HOME="/opt/hypre"
export PATH="$MPI_HOME/bin:/opt/intel/fc64/bin/intel64:$PATH"
export LD_LIBRARY_PATH="$MPI_HOME/lib:$HYPRE_HOME/lib:/opt/intel/fc64/lib/intel64:$LD_LIBRARY_PATH"
export INTEL_LICENSE_FILE="/opt/intel/licenses"

#linking
export LDFLAGS="-lstdc++ -L/opt/hypre/lib -lHYPRE"

cd trunk

# First compile modules until mathlibs because we need then BLAS and LAPACK for ScaLAPACK, MUMPS and SuperLU
modules_first="matc umfpack mathlibs"
for m in $modules_first; do
    cd $m ; make distclean ; ./configure --prefix=$ELMER_HOME --with-mpi-dir=$MPI_HOME --libdir=$ELMER_HOME/lib && make && make install && cd ..
done

# If we use MUMPS, we get the directory name containing it, then this will be used also fo the compilation of 
# MUMPS if we need to do that. Be carefull that choosing not to use MUMPS and still trying to compile it is 
# not a valid operation.
if test $USEMUMPS -eq 1; then
MUMPSDIR=$(cat /opt/INITIALIZE.val | grep "MUMPSDIR" | awk -F":" '{print $2}')
fi

if test $MUMPS -eq 1 ; then
echo "*******************************************************"
echo "We want MUMPS. Compile BLACS and ScaLAPACK."
echo "*******************************************************"
#Compile BLACS
cd /opt/BLACS && make mpi what=clean ; make tester what=clean ; make mpi && make tester
if test $TESTBLACS -eq 1 ; then
echo "TEST BLACS"
cd TESTING/EXE
mpirun -n 8 xFbtest_MPI-LINUX-0
mpirun -n 8 xCbtest_MPI-LINUX-0
fi

cd /opt
#Compile ScaLAPACK (including tests executables and examples) and MUMPS
cd scalapack-1.8.0 ; make clean ; make
if test $TESTSCALAPACK -eq 1 ; then
make exe ; make example
cd PBLAS/TESTING
echo "RUNNING THE PBLAS TEST SUITE"
mpirun -n 8 xspblas1tst
mpirun -n 8 xdpblas1tst
mpirun -n 8 xcpblas1tst
mpirun -n 8 xzpblas1tst
mpirun -n 8 xspblas2tst
mpirun -n 8 xdpblas2tst
mpirun -n 8 xcpblas2tst
mpirun -n 8 xzpblas2tst
mpirun -n 8 xspblas3tst
mpirun -n 8 xdpblas3tst
mpirun -n 8 xcpblas3tst
mpirun -n 8 xzpblas3tst
mpirun -n 8 xspblas1tim
mpirun -n 8 xdpblas1tim
mpirun -n 8 xcpblas1tim
mpirun -n 8 xzpblas1tim
mpirun -n 8 xspblas2tim
mpirun -n 8 xdpblas2tim
mpirun -n 8 xcpblas2tim
mpirun -n 8 xzpblas2tim
mpirun -n 8 xspblas3tim
mpirun -n 8 xdpblas3tim
mpirun -n 8 xcpblas3tim
mpirun -n 8 xzpblas3tim
cd /opt/scalapack-1.8.0/REDIST/TESTING
echo "RUNNING THE REDIST TEST SUITE"
mpirun -n 8 xigemr
mpirun -n 8 xsgemr
mpirun -n 8 xdgemr
mpirun -n 8 xcgemr
mpirun -n 8 xzgemr
mpirun -n 8 xitrmr
mpirun -n 8 xstrmr
mpirun -n 8 xdtrmr
mpirun -n 8 xctrmr
mpirun -n 8 xztrmr
cd /opt/scalapack-1.8.0/TESTING
echo "RUNNING THE SCALAPACK TEST SUITE (only for double precision numbers)"
mpirun -n 8 xdlu
mpirun -n 8 xdllt
mpirun -n 8 xddblu
mpirun -n 8 xdgblu
mpirun -n 8 xddtlu
mpirun -n 8 xdpbllt
mpirun -n 8 xdptllt
mpirun -n 8 xdls
mpirun -n 8 xdqr
mpirun -n 8 xdhrd
mpirun -n 8 xdtrd
mpirun -n 8 xdbrd
mpirun -n 8 xdinv
mpirun -n 8 xdsep
mpirun -n 8 xdgsep
mpirun -n 8 xdnep
mpirun -n 8 xdsvd
fi

cd /opt

echo "COMPILING MUMPS"
cd $MUMPSDIR ; make clean ; make && cd ..
fi

if test $SUPERLU -eq 1 ; then
echo "*******************************************************"
echo "We want SuperLU. Compiling ParMetis and SuperLU."
echo "*******************************************************"
cd /opt/ParMetis-3.1.1 ; make clean ; make
if test $TESTPARMETIS -eq 1 ; then
cd Graphs
echo "TESTING PARMETIS"
mpirun -n 8 ptest rotor.graph
fi

cd /opt

cd SuperLU_DIST_2.3 ; make clean ; make && cd EXAMPLE ; make clean ; make && cd /opt
fi

#the compiler flags updated after we get the MUMPS compiled
if test $USEMUMPS -eq 1; then
export CFLAGS="$CFLAGS -I/opt/$MUMPSDIR/include"
export CXXFLAGS="$CXXFLAGS -I/opt/$MUMPSDIR/include"
export FCFLAGS="$FCFLAGS -I/opt/$MUMPSDIR/include"
export F77FLAGS="$F77FLAGS -I/opt/$MUMPSDIR/include"
export FFLAGS="$FFLAGS -I/opt/$MUMPSDIR/include"
export F90FLAGS="$F90FLAGS -I/opt/$MUMPSDIR/include"
fi

#linking after we get the numerical libraries compiled and set Fortran preprocessor flags
if test $USEMUMPS -eq 1 ; then
export FCPPFLAGS="-DHAVE_MUMPS"
export LDFLAGS="$LDFLAGS -L/opt/$MUMPSDIR/lib -ldmumps -lmumps_common -lpord -L/opt/scalapack-1.8.0 -lscalapack /opt/BLACS/LIB/blacs_MPI-LINUX-0.a /opt/BLACS/LIB/blacsCinit_MPI-LINUX-0.a /opt/BLACS/LIB/blacsF77init_MPI-LINUX-0.a /opt/BLACS/LIB/blacs_MPI-LINUX-0.a"
fi

if test $USESUPERLU -eq 1 ; then
export FCPPFLAGS="$FCPPFLAGS -DHAVE_SUPERLU"
export LDFLAGS="$LDFLAGS -L/opt/SuperLU_DIST_2.3/lib -lsuperlu_dist_2.3"
fi

if test $USEPARDISO -eq 1 ; then 
echo "*******************************************************"
echo "We want Pardiso. Linking to it"
echo "*******************************************************"
export FCPPFLAGS="$FCPPFLAGS -DHAVE_PARDISO"
export LDFLAGS="$LDFLAGS -L/opt/pardiso -lpardiso_GNU42_EM64T_INT64_P"
fi

#Libraries path
if test $USEMUMPS -eq 1 ; then
export LD_LIBRARY_PATH="$MPI_HOME/lib:$HYPRE_HOME/lib:/opt/scalapack-1.8.0:/opt/BLACS/LIB:/opt/$MUMPSDIR/lib:$LD_LIBRARY_PATH"
fi

if test $USESUPERLU -eq 1 ; then
export LD_LIBRARY_PATH="$MPI_HOME/lib:$HYPRE_HOME/lib:/opt/scalapack-1.8.0:/opt/BLACS/LIB:/opt/BLACS/LIB:/opt/$MUMPSDIR/lib:/opt/SuperLU_DIST_2.3/lib:$LD_LIBRARY_PATH"
fi

if test $USEPARDISO -eq 1 ; then
export LD_LIBRARY_PATH="$MPI_HOME/lib:$HYPRE_HOME/lib:/opt/scalapack-1.8.0:/opt/BLACS/LIB:/opt/BLACS/LIB:/opt/$MUMPSDIR/lib:/opt/SuperLU_DIST_2.3/lib:/opt/pardiso:$LD_LIBRARY_PATH"
fi

cd $ELMER_HOME/trunk

#Compile the rest of elmer distribution
modules_third="elmergrid meshgen2d eio hutiter fem post"
# configure and build
for m in $modules_third; do
    cd $m ; make distclean ; ./configure --prefix=$ELMER_HOME --with-mpi-dir=$MPI_HOME --libdir=$ELMER_HOME/lib && make && make install && cd ..
done

if test $GETNEWSVN -eq 1 ; then
cd /opt/elmerdev
cp -f /opt/README64bits .

OPENMPI=$(cat /opt/MPI_HYPRE_VER.val | grep "OPENMPI" | awk -F":" '{print $2}')
HYPRE=$(cat /opt/MPI_HYPRE_VER.val | grep "HYPRE" | awk -F":" '{print $2}')
BLACS=$(cat /opt/NUMERICS_VER.val | grep "BLACS" | awk -F":" '{print $2}')
MUMPS=$(cat /opt/NUMERICS_VER.val | grep "MUMPS" | awk -F":" '{print $2}')
PARMETIS=$(cat /opt/NUMERICS_VER.val | grep "PARMETIS" | awk -F":" '{print $2}')
SUPERLU=$(cat /opt/NUMERICS_VER.val | grep "SUPERLU" | awk -F":" '{print $2}')
SCALAPACK=$(cat /opt/NUMERICS_VER.val | grep "SCALAPACK" | awk -F":" '{print $2}')
PARDISO=$(cat /opt/NUMERICS_VER.val | grep "PARDISO" | awk -F":" '{print $2}')

echo "Build compiled from trunk revision $SVN" > README64bits
echo "Parallel build compiled with Open MPI ($OPENMPI)" >> README64bits
echo "Compiled with HYPRE ($HYPRE)" >> README64bits

if test $USEMUMPS -eq 1; then
echo "Compiled with MUMPS ($MUMPS). Dependency to BLACS ($BLACS) and ScaLAPACK ($SCALAPACK)" >> README64bits
fi

if test $USESUPERLU -eq 1 ; then
echo "Compiled with Super LU ($SUPERLU). Dependency to ParMetis ($PARMETIS)" >> README64bits
fi

if test $USEPARDISO -eq 1 ; then
echo "Compiled with Pardiso ($PARDISO)" >> README64bits
fi

echo "Number of test failures:" >> README64bits
echo "Running solver tests"
cd trunk/fem
make check >> /opt/elmerdev/README64bits
cat /opt/elmerdev/README64bits
fi

# Debug version ####################################################
if test $DEBUG_BUILD -eq 1 ; then

echo "##################################################"
echo "Compiles debug build"
echo "#################################################"

cd /opt

if test -d $ROOT_DEBUG_DIRECTORY ; then

cd /opt/elmerdbg
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
rm -rf trunk
fi
fi
echo "Do ls #########"
ls
echo "###"
else
echo "No original elmer directry for debug version. Creates one."
mkdir elmerdbg
cd elmerdbg

fi

if test $GETNEWSVN -eq 1 ; then
echo "SVN revision $SVN will be compiled in debug mode"
svn -r $SVN co svn://svn.code.sf.net/p/elmerfem/code/trunk/
fi

#the compiler flags
export CFLAGS="-I/opt/hypre/include -g"
export CXXFLAGS="-I/opt/hypre/include -g"
export FCFLAGS="-I/opt/hypre/include -g"
export F77FLAGS="-I/opt/hypre/include -g"
export FFLAGS="-I/opt/hypre/include -g"
export F90FLAGS="-I/opt/hypre/include -g"

#linking
export LDFLAGS="-lstdc++ -L/opt/hypre/lib -lHYPRE"

export FCPPFLAGS=""

#paths
export ELMER_HOME="/opt/elmerdbg"
export MPI_HOME="/opt/openmpi"
export HYPRE_HOME="/opt/hypre"
export PATH="$MPI_HOME/bin:$PATH"
export LD_LIBRARY_PATH="$MPI_HOME/lib:$HYPRE_HOME/lib:$LD_LIBRARY_PATH"

if test $USEMUMPS -eq 1; then
export CFLAGS="$CFLAGS -I/opt/$MUMPSDIR/include"
export CXXFLAGS="$CXXFLAGS -I/opt/$MUMPSDIR/include"
export FCFLAGS="$FCFLAGS -I/opt/$MUMPSDIR/include"
export F77FLAGS="$F77FLAGS -I/opt/$MUMPSDIR/include"
export FFLAGS="$FFLAGS -I/opt/$MUMPSDIR/include"
export F90FLAGS="$F90FLAGS -I/opt/$MUMPSDIR/include"
fi

if test $USEMUMPS -eq 1 ; then
export FCPPFLAGS="-DHAVE_MUMPS"
export LDFLAGS="$LDFLAGS -L/opt/$MUMPSDIR/lib -ldmumps -lmumps_common -lpord -L/opt/scalapack-1.8.0 -lscalapack /opt/BLACS/LIB/blacs_MPI-LINUX-0.a /opt/BLACS/LIB/blacsCinit_MPI-LINUX-0.a /opt/BLACS/LIB/blacsF77init_MPI-LINUX-0.a /opt/BLACS/LIB/blacs_MPI-LINUX-0.a"
fi

if test $USESUPERLU -eq 1 ; then
export FCPPFLAGS="$FCPPFLAGS -DHAVE_SUPERLU"
export LDFLAGS="$LDFLAGS -L/opt/SuperLU_DIST_2.3/lib -lsuperlu_dist_2.3"
fi

if test $USEPARDISO -eq 1 ; then
echo "*******************************************************"
echo "We want Pardiso. Linking to it"
echo "*******************************************************"
export FCPPFLAGS="$FCPPFLAGS -DHAVE_PARDISO"
export LDFLAGS="$LDFLAGS -L/opt/pardiso -lpardiso_GNU42_EM64T_INT64_P"
fi

#Libraries path
if test $USEMUMPS -eq 1 ; then
export LD_LIBRARY_PATH="$MPI_HOME/lib:$HYPRE_HOME/lib:/opt/scalapack-1.8.0:/opt/BLACS/LIB:/opt/$MUMPSDIR/lib:$LD_LIBRARY_PATH"
fi

if test $USESUPERLU -eq 1 ; then
export LD_LIBRARY_PATH="$MPI_HOME/lib:$HYPRE_HOME/lib:/opt/scalapack-1.8.0:/opt/BLACS/LIB:/opt/BLACS/LIB:/opt/$MUMPSDIR/lib:/opt/SuperLU_DIST_2.3/lib:$LD_LIBRARY_PATH"
fi

if test $USEPARDISO -eq 1 ; then
export LD_LIBRARY_PATH="$MPI_HOME/lib:$HYPRE_HOME/lib:/opt/scalapack-1.8.0:/opt/BLACS/LIB:/opt/BLACS/LIB:/opt/$MUMPSDIR/lib:/opt/SuperLU_DIST_2.3/lib:/opt/pardiso:$LD_LIBRARY_PATH"
fi

cd $ELMER_HOME/trunk

#Compile the elmer distribution
modules_debug="matc umfpack mathlibs elmergrid meshgen2d eio hutiter fem post"
# configure and build
for m in $modules_debug; do
    cd $m ; make distclean ; ./configure --prefix=$ELMER_HOME --with-mpi-dir=$MPI_HOME --libdir=$ELMER_HOME/lib && make && make install && cd ..
done

if test $GETNEWSVN -eq 1 ; then
cd /opt/elmerdbg
cp -f /opt/README64bits .

echo "Debug build compiled from trunk revision $SVN" > README64bits
echo "Parallel build compiled with Open MPI ($OPENMPI)" >> README64bits
echo "Compiled with HYPRE ($HYPRE)" >> README64bits

if test $USEMUMPS -eq 1; then
echo "Compiled with MUMPS ($MUMPS). Dependency to BLACS ($BLACS) and ScaLAPACK ($SCALAPACK)" >> README64bits
fi

if test $USESUPERLU -eq 1 ; then
echo "Compiled with Super LU ($SUPERLU). Dependency to ParMetis ($PARMETIS)" >> README64bits
fi

if test $USEPARDISO -eq 1 ; then
echo "Compiled with Pardiso ($PARDISO)" >> README64bits
fi

echo "Number of test failures:" >> README64bits
echo "Running solver tests"
cd /trunk/fem
make check >> /opt/elmerdbg/README64bits
cat /opt/elmerdbg/README64bits
fi
fi ## end Debub


cd /opt/
rm -f REVISION.val
rm -f MPI_HYPRE_VER.val
rm -f NUMERICS_VER.val
rm -f README64bits
rm -f INITIALIZE.val

echo "#############################################"
echo "Compilation completed. Have fun!!! "
echo "#############################################"

rm -f build-elmerMpi.sh  

#exit the host
exit
