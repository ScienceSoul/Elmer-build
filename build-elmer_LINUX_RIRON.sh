#!/bin/bash
############################################################################################################
# Master script.
# Builds Elmer accross all LINUX machines on Rironseppyou network.
# Parallel builds are compiled only for multi-cores/processors machines, serial
# builds are compiled for both single core and multi-cores/processors  machines.
# On 64 bits machines, several numerical libraries are compiled and linked to
# Elmer if needed (and if not broken), the executed script on those machines implement 
# the logic to specify which one to compile and to link to the solver. 
#
# Master script calls the following slaves:
#
#      build-elmer32bits.sh: builds Elmer on 32 bits machines.
#      build_MPI_HYPRE.sh: builds Open MPI and HYPRE
#      build-elmerMpi.sh: builds Elmer on 64 bits machines with MPI and numerical libraries. 
# 
# Compiles Open MPI if specified.
# Numerical libraries available: BLACS, ScaLAPACK, MUMPS, SuperLU DIST, Pardiso, HYPRE.
# Parallel graph and mesh partitioning: ParMETIS.
# Parallel library: Open MPI.
#
# Version number of numerical libraries (besides HYPRE) in NUMERICS_VER.val
# Version number of Open MPI and HYPRE in MPI_HYPRE_VER.val
# Version number of SVN revision of Elmer source files in REVISION.val
#
#     Created date: March 3, 2009 
#                   version alpha
#
#     Modified date: 
#                    March 9, 2009.
#                    Change paths where some files are copied on the servers for directory checking 
#                    support in slaves script. Removed hard coded values for options,
#                    it now reads from INITIALIZE.val. Some clean up and code reorganization.
#                    Version 1.0.
#                     Options in INIATAILIZE.val
#                        NYE -> specifies if Elmer will be compiled on Nye
#                        BUDD -> specifies if Elmer will be compiled on Budd
#                        GLEN -> specifies if Elmer will be compiled on Glen
#                        MARVIN -> specifies if Elmer will be compiled on Marvin
#                        ZAPHOD -> specifies if Elmer will be compiled on Zaphod
#                        OPENMPI_HYPRE -> specifies if new binaries of Open MPI and Hypre will be compiled
#                        machine -> specifies on which machines Open MPI and Hypre will be compiled
#                        COPYREADME -> specifies if a new README file will be created in remote host
#                        GETNEWSVN -> specifies if new svn revision will be used for Elmer compilation
#                        MUMPS -> specifies if MUMPS will be compiled
#                        SUPERLU -> specifies if SuperLU will be compiled
#                        USEMUMPS -> specifies if Elmer will be compiled with MUMPS
#                        USESUPERLU -> specifies if Elmer will be compiled with SuperLU
#                        USEPARDISO -> specifies if Elmer will be compiled with Pardiso
#                        TESTBLACS -> specifies if Blacs tests will be performed
#                        TESTSCALAPACK -> specifies if ScaLapack tests will be performed
#                        TESTPARMETIS -> specifies if ParMetis tests will be performed
#                        DEBUG_BUILD -> specifies if a debug build of Elmer  will be compiled
#
#                    September 15, 2009
#                    Add compilation for computer Eddie.
#
#                    October 25, 2010
#                    Add compilation for computer Hactar
#
#                    September 10, 2014
#                    Add compilation for computer Deepthough
#
#     Author: Hakime Seddik
#     Institute of Low Tenperature Science, Hokkaido University.
############################################################################################################

#Options:

#Computers where we compile
NYE=$(cat INITIALIZE.val | grep "NYE" | awk -F":" '{print $2}')
BUDD=$(cat INITIALIZE.val | grep "BUDD" | awk -F":" '{print $2}')
GLEN=$(cat INITIALIZE.val | grep "GLEN" | awk -F":" '{print $2}')
MARVIN=$(cat INITIALIZE.val | grep "MARVIN" | awk -F":" '{print $2}')
ZAPHOD=$(cat INITIALIZE.val | grep "ZAPHOD" | awk -F":" '{print $2}')
EDDIE=$(cat INITIALIZE.val | grep "EDDIE" | awk -F":" '{print $2}')
HACTAR=$(cat INITIALIZE.val | grep "HACTAR" | awk -F":" '{print $2}')
DEEPTHOUGHT=$(cat INITIALIZE.val | grep "DEEPTHOUGHT" | awk -F":" '{print $2}')

#Do we compile Open MPI and HYPRE
OPENMPI_HYPRE=$(cat INITIALIZE.val | grep "OPENMPI_HYPRE" | awk -F":" '{print $2}')

#Where we compile Open MPI and HYPRE
machine=$(cat INITIALIZE.val | grep "machine" | awk -F":" '{print $2}')

# 0 if compiling from already available SVN revision 
#(please set also the value in the building scripts, variable $GETNEWSVN)
COPYREADME=$(cat INITIALIZE.val | grep "COPYREADME" | awk -F":" '{print $2}')
#######################################################################################

OPENMPI=$(cat MPI_HYPRE_VER.val | grep "OPENMPI" | awk -F":" '{print $2}')
HYPRE=$(cat MPI_HYPRE_VER.val | grep "HYPRE" | awk -F":" '{print $2}')

touch README32bits
touch README64bits 

chmod u+x build-elmer32bits.sh 

#NYE ############################################################
if test $NYE -eq 1 ; then
echo "#############################################"
echo "Compiling Elmer on NYE"
echo "#############################################"
scp build-elmer32bits.sh root@nye:/opt/
scp INITIALIZE.val root@nye:/opt/
scp REVISION.val root@nye:/opt/

if test $COPYREADME -eq 1 ; then
scp README32bits root@nye:/opt/
fi

ssh root@nye "/opt/build-elmer32bits.sh"
fi

#BUDD ############################################################
if test $BUDD -eq 1 ; then
echo "#############################################"
echo "Compiling Elmer on BUDD"
echo "#############################################"
scp build-elmer32bits.sh root@budd:/opt/
scp INITIALIZE.val root@budd:/opt/
scp REVISION.val root@budd:/opt/

if test $COPYREADME -eq 1 ; then
scp README32bits root@budd:/opt/
fi

ssh root@budd "/opt/build-elmer32bits.sh"
fi

chmod u-x build-elmer32bits.sh

#Open MPI and HYPRE ##############################################
if test $OPENMPI_HYPRE -eq 1 ; then
echo "#############################################"
echo "Compiling Open MPI and HYPRE"
echo "#############################################"
chmod u+x build_MPI_HYPRE.sh

for m in $machine; do
echo "###############"
echo "Go for $m"
echo "##############"
scp $OPENMPI.tar.gz root@$m:/opt/
scp $HYPRE.tar.gz root@$m:/opt/
scp build_MPI_HYPRE.sh root@$m:/opt/
scp MPI_HYPRE_VER.val root@$m:/opt/
scp INITIALIZE.val root@$m:/opt/

ssh root@$m "/opt/build_MPI_HYPRE.sh"
done
chmod u-x build_MPI_HYPRE.sh
fi

chmod u+x build-elmerMpi.sh

#glen ############################################################
if test $GLEN -eq 1 ; then
echo "#############################################"
echo "Compiling Elmer on GLEN"
echo "#############################################"
scp build-elmerMpi.sh root@glen:/opt/
scp INITIALIZE.val root@glen:/opt/
scp REVISION.val root@glen:/opt/
scp MPI_HYPRE_VER.val root@glen:/opt/
scp NUMERICS_VER.val root@glen:/opt/

if test $COPYREADME -eq 1 ; then
scp README64bits root@glen:/opt/
fi

ssh root@glen "/opt/build-elmerMpi.sh"
fi

#marvin ############################################################
if test $MARVIN -eq 1 ; then
echo "#############################################"
echo "Compiling Elmer on MARVIN"
echo "#############################################"
scp build-elmerMpi.sh root@marvin:/opt/
scp INITIALIZE.val root@marvin:/opt/
scp REVISION.val root@marvin:/opt/
scp MPI_HYPRE_VER.val root@marvin:/opt/
scp NUMERICS_VER.val root@marvin:/opt/

if test $COPYREADME -eq 1 ; then
scp README64bits root@marvin:/opt/
fi

ssh root@marvin "/opt/build-elmerMpi.sh"
fi

#ZAPHOD ############################################################
if test $ZAPHOD -eq 1 ; then
echo "#############################################"
echo "Compiling Elmer on ZAPHOD"
echo "#############################################"
scp build-elmerMpi.sh root@zaphod:/opt/
scp INITIALIZE.val root@zaphod:/opt/
scp REVISION.val root@zaphod:/opt/
scp MPI_HYPRE_VER.val root@zaphod:/opt/
scp NUMERICS_VER.val root@zaphod:/opt/

if test $COPYREADME -eq 1 ; then
scp README64bits root@zaphod:/opt/
fi

ssh root@zaphod "/opt/build-elmerMpi.sh"
fi

#EDDIE ############################################################
if test $EDDIE -eq 1 ; then
echo "#############################################"
echo "Compiling Elmer on EDDIE"
echo "#############################################"
scp build-elmerMpi.sh root@eddie:/opt/
scp INITIALIZE.val root@eddie:/opt/
scp REVISION.val root@eddie:/opt/
scp MPI_HYPRE_VER.val root@eddie:/opt/
scp NUMERICS_VER.val root@eddie:/opt/

if test $COPYREADME -eq 1 ; then
scp README64bits root@eddie:/opt/
fi

ssh root@eddie "/opt/build-elmerMpi.sh"
fi

#Hactar ############################################################
if test $HACTAR -eq 1 ; then
echo "#############################################"
echo "Compiling Elmer on HACTAR"
echo "#############################################"
scp build-elmerMpi.sh root@hactar:/opt/
scp INITIALIZE.val root@hactar:/opt/
scp REVISION.val root@hactar:/opt/
scp MPI_HYPRE_VER.val root@hactar:/opt/
scp NUMERICS_VER.val root@hactar:/opt/

if test $COPYREADME -eq 1 ; then
scp README64bits root@hactar:/opt/
fi

ssh root@hactar "/opt/build-elmerMpi.sh"
fi

#Deepthought ############################################################
if test $DEEPTHOUGHT -eq 1 ; then
echo "#############################################"
echo "Compiling Elmer on DEEPTHOUGHT"
echo "#############################################"
scp build-elmerMpi.sh root@deepthought:/opt/
scp INITIALIZE.val root@deepthought:/opt/
scp REVISION.val root@deepthought:/opt/
scp MPI_HYPRE_VER.val root@deepthought:/opt/
scp NUMERICS_VER.val root@deepthought:/opt/

if test $COPYREADME -eq 1 ; then
scp README64bits root@deepthought:/opt/
fi

ssh root@deepthought "/opt/build-elmerMpi.sh"
fi

#we are ending
chmod u-x build-elmerMpi.sh

rm -f README32bits
rm -f README64bits

#Here you are my friend!!
echo "###################################################################"
echo "ALL DONE!!"
echo "###################################################################"
