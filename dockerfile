# syntax=docker/dockerfile:1
FROM almalinux:9.3-20231124 AS packages
        LABEL maintainer.name="Yulei ZHANG"
        LABEL version="1.0"
        LABEL maintainer.email="avencast@fastmail.com"
        
        SHELL ["/bin/bash", "-c"]
        
        ENV LANG=C.UTF-8
        
        # install general dependencies
        COPY packages packages
        
        RUN dnf update -y ;\
            ln -sf /usr/share/zoneinfo/UTC /etc/localtime ;\
            dnf -y install wget git gdb valgrind;\
            dnf grouplist ;\
            dnf groupinstall "Development Tools" -y ;\
            dnf install -y epel-release gcc gcc-c++ openssl-devel bzip2-devel libffi-devel zlib-devel make;\
            xargs -a packages dnf install -y ;\
            dnf autoremove -y ;\
            dnf clean all ;\
            ldconfig
         # replace perf to fix the error:"perf not found for kernel xxx"
         # strip is to solve the problem in qt5 which checks the compatibility with the host kernel.

# Build BOOST
# FROM packages AS boost
#         ARG BOOST_VERSION=1_78_0
        
#         WORKDIR /root
#                 ADD Downloads/boost_${BOOST_VERSION}.tar.gz .
                
#                 RUN cd boost_${BOOST_VERSION} ;\
#                     ./bootstrap.sh --prefix=/opt/boost ;\
#                     ./b2 -j$(nproc) install

# General base
# FROM packages AS base
#         ENV BOOST_ROOT="/opt/boost"
#         ENV BOOST_LIBRARYDIR="${BOOST_ROOT}/lib"
#         ENV BOOST_INCLUDEDIR="${BOOST_ROOT}/include"
#         ENV LD_LIBRARY_PATH="${BOOST_ROOT}/lib:${LD_LIBRARY_PATH}"
#         ENV BOOSTROOT="${BOOST_ROOT}"
#         ENV BOOST_LIB="${BOOST_ROOT}/lib"
#         ENV BOOST_IGNORE_SYSTEM_PATHS=1
        
#         COPY --from=boost ${BOOST_ROOT} ${BOOST_ROOT}

# Install CMake 3.27 from source
FROM packages AS base
        ARG CMAKE_VERSION=3.28.3
        
        WORKDIR /root
                ADD downloads/cmake-${CMAKE_VERSION}.tar.gz .
                # RUN wget https://github.com/Kitware/CMake/releases/download/v3.27.9/cmake-3.27.9.tar.gz ;\
                #         tar -xzf cmake-${CMAKE_VERSION}.tar.gz ;\
                RUN mkdir -p build;\
                        cd build ;\
                        ../cmake-${CMAKE_VERSION}/bootstrap --parallel=$(nproc) ;\
                        make -j$(nproc) install ;\
                        cd ../ && rm -rf cmake-${CMAKE_VERSION} cmake-${CMAKE_VERSION}.tar.gz build
                RUN cmake --version        

# Build ROOT
FROM base AS root
        ARG ROOT_VERSION=6.30.04
        
        WORKDIR /root
                ADD downloads/root_v${ROOT_VERSION}.source.tar.gz .
                # RUN wget https://root.cern/download/root_v${ROOT_VERSION}.source.tar.gz ;\
                # RUN tar -xzf root_v${ROOT_VERSION}.source.tar.gz ;
        
                RUN mkdir -p build ;\
                    cd build ;\
                    cmake -DCMAKE_INSTALL_PREFIX=/opt/root \
                          -DCMAKE_CXX_STANDARD=20 \
                          -DCXX_STANDARD_STRING=20 \
                          -Dxrootd=OFF \
                          ../root-${ROOT_VERSION} ;\
                #     cmake --build . --target install -- -j$(nproc)
                    cmake --build . --target install -- -j4

# Build Geant4
FROM base AS geant4
        ARG G4_VERSION=11.2.1
        
        WORKDIR /root
                ADD downloads/geant4-v${G4_VERSION}.tar.gz .
                # RUN wget https://gitlab.cern.ch/geant4/geant4/-/archive/v${G4_VERSION}/geant4-v${G4_VERSION}.tar.gz
                # RUN ls && tar -xzf geant4-v${G4_VERSION}.tar.gz ;

                RUN mkdir -p build ;\
                    cd build ;\
                    cmake -DCMAKE_INSTALL_PREFIX=/opt/geant4 \
                          -DGEANT4_INSTALL_DATA=OFF \
                          -DGEANT4_USE_GDML=ON \
                          -DGEANT4_USE_QT=ON \
                          -DGEANT4_USE_PYTHON=ON \
                          -DCMAKE_CXX_STANDARD=20 \
                          -DGEANT4_USE_SYSTEM_EXPAT=OFF \
                          ../geant4-v${G4_VERSION} ;\
                #     make -j$(nproc) install
                    make -j4 install
                
                COPY downloads/data /opt/geant4/share/Geant4-${G4_VERSION}/data
      
# Release
FROM base AS release
        WORKDIR /root
        COPY --from=root /opt/root /opt/root
        COPY --from=geant4 /opt/geant4 /opt/geant4
        # Copy scripts
        # COPY root /root
        # COPY entry-point.sh /entry-point.sh
        
        # ENTRYPOINT ["/entry-point.sh"]
        
        CMD bash
