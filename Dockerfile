FROM ubuntu:22.04  AS ubuntu_with_libs

RUN apt update

RUN apt-get install software-properties-common -y
RUN add-apt-repository universe
RUN apt update

# Install cpp compiler, lapack, make
RUN apt-get install build-essential libssl-dev libgsl-dev liblapack-dev wget make -y

# Boost required by CMakeList
# Boost need configured tzdata, but usually it runs in an interactive mode, following lines ommit that
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends tzdata
RUN dpkg-reconfigure tzdata
# Normal Boost instalation
RUN apt-get install libboost-all-dev -y

# Additional dependencies
RUN apt-get -y install libeigen3-dev
RUN apt-get -y install libfmt-dev

RUN apt install git -y

RUN apt install python3 -y
RUN apt install python3-pip -y

# Install CMake
WORKDIR /opt
RUN mkdir -p /opt/temp
WORKDIR /opt/temp
RUN wget https://github.com/Kitware/CMake/releases/download/v3.23.1/cmake-3.23.1.tar.gz
RUN tar -zxvf cmake-3.23.1.tar.gz
WORKDIR /opt/temp/cmake-3.23.1
RUN ./bootstrap
RUN make
RUN make install

FROM ubuntu_with_libs AS ubuntu_with_viskit

# get viskit and upload modified files
WORKDIR /opt
RUN git clone https://gitlab.com/bminch/viskit.git

COPY viskit_mod/requirements.txt /opt/viskit/requirements.txt
COPY viskit_mod/faiss_generator.py /opt/viskit/python/viskit/knn_graph/faiss_generator.py
COPY viskit_mod/tsne.cpp /opt/viskit/viskit/embed/cast/tsne/tsne.cpp

WORKDIR /opt/viskit

# Get Python dependencies
RUN pip install -r ./requirements.txt

# Initialize submodules
RUN git submodule init
RUN git submodule update

FROM ubuntu_with_viskit

WORKDIR /opt/viskit
RUN cmake ./CMakeLists.txt
RUN make

RUN chmod +x /opt/viskit/viskit_offline/viskit_offline