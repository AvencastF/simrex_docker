#!/bin/bash

mkdir -p downloads

CMAKE_VERSION="3.28.3"
ROOT_VERSION="6.30.04"
GEANT4_VERSION="11.2.1"

wget https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}.tar.gz

wget https://root.cern/download/root_v${ROOT_VERSION}.source.tar.gz

wget https://gitlab.cern.ch/geant4/geant4/-/archive/v${GEANT4_VERSION}/geant4-v${GEANT4_VERSION}.tar.gz

mv cmake-${CMAKE_VERSION}.tar.gz downloads/
mv root_v${ROOT_VERSION}.source.tar.gz downloads/
mv geant4-v${GEANT4_VERSION}.tar.gz downloads/


# For Geant4 Data
DATASETDIR="downloads/data"

DATASETS="
G4ENSDFSTATE2.3.tar.gz
G4INCL1.2.tar.gz
G4ABLA3.3.tar.gz
G4SAIDDATA2.0.tar.gz
RealSurface2.2.tar.gz
G4PII1.3.tar.gz
G4PARTICLEXS4.0.tar.gz
RadioactiveDecay5.6.tar.gz
GPhotonEvaporation5.7.tar.gz
G4EMLOW8.5.tar.gz
G4NDL4.7.tar.gz
"

mkdir -p $DATASETDIR
for DATASET in $DATASETS; do
    aria2c -o $DATASETDIR/$DATASET https://geant4-data.web.cern.ch/geant4-data/datasets/$DATASET
    tar zxf $DATASETDIR/$DATASET -C $DATASETDIR
    rm $DATASETDIR/$DATASET
done

echo "#########################################################"
echo " Data set dir: $DATASETDIR"
echo "#########################################################"
