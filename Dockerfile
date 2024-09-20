FROM ubuntu:22.04

ENV FAISS_DIR=faiss-1.8.0

RUN apt update && apt install -y wget
# RUN wget https://repo.anaconda.com/archive/Anaconda3-2020.11-Linux-x86_64.sh
# RUN bash Anaconda3-2020.11-Linux-x86_64.sh -b
# ENV PATH /root/anaconda3/bin:$PATH

RUN wget https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh
RUN chmod a+x Miniforge3-Linux-x86_64.sh
RUN bash ./Miniforge3-Linux-x86_64.sh -b
ENV PATH /root/miniforge3/bin:$PATH

RUN conda config --set proxy_servers.https proxy-dmz.intel.com:912
RUN conda config --set proxy_servers.http proxy-dmz.intel.com:912

RUN python3 -m pip install ansicolors==1.1.8 docker==5.0.2
RUN conda install -c pytorch h5py numpy mkl=2023 blas=1.0=mkl

# https://developpaper.com/a-pit-of-mkl-library-in-linux-anaconda/
# ENV LD_PRELOAD /root/anaconda3/lib/libmkl_core.so:/root/anaconda3/lib/libmkl_sequential.so 

RUN apt install -y build-essential 
RUN apt install -y wget git vim
RUN apt install -y software-properties-common lsb-release
# WORKDIR /home/
#Install Latest CMake
RUN wget -O - https://apt.kitware.com/keys/kitware-archive-latest.asc 2>/dev/null | gpg --dearmor - | tee /etc/apt/trusted.gpg.d/kitware.gpg >/dev/null
RUN apt-add-repository "deb https://apt.kitware.com/ubuntu/ $(lsb_release -cs) main"
RUN apt update -y
RUN apt install kitware-archive-keyring
# RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 6AF7F09730B3F0A4
RUN apt update -y
RUN apt install cmake -y
RUN apt install -y build-essential libtool autoconf unzip wget
# RUN apt-get update -y

RUN apt install swig -y

RUN apt-get install -y python3-dev
RUN apt-get install -y python3-numpy-dev
RUN apt-get install -y python3-pip
RUN apt-get install -y git

WORKDIR /home/app/
RUN git clone https://github.com/oneapi-src/oneDNN.git
WORKDIR /home/app/oneDNN
RUN mkdir -p build
WORKDIR /home/app/oneDNN/build
RUN cmake ..
RUN make -j
RUN make install


# ENV http_proxy child-prc.intel.com:913
# ENV https_proxy child-prc.intel.com:913
RUN pip3 install psutil 
RUN pip3 install pyyaml
RUN pip3 install scikit-learn scipy matplotlib
# RUN pip3 install tensorflow

WORKDIR /home/app
ADD faiss-1.8.0 ./faiss
RUN rm -rf /home/app/faiss/build

ADD run_conda_env.sh /home/app/faiss/
ADD build_faiss.sh /home/app/faiss/
RUN chmod a+x /home/app/faiss/run_conda_env.sh
RUN chmod a+x /home/app/faiss/build_faiss.sh


WORKDIR /home/app/faiss/
# RUN ./run_conda.sh
RUN ./run_conda_env.sh
RUN ./build_faiss.sh

RUN cat /sys/kernel/mm/transparent_hugepage/enabled
# 检查 Transparent Huge Pages (THP) 是否为 'always'，如果不是则退出构建
RUN if [ "$(cat /sys/kernel/mm/transparent_hugepage/enabled | grep -o '\[always\]')" != "[always]" ]; then \
        echo "Transparent Huge Pages is not set to 'always'. Exiting..."; \
        exit 1; \
    fi

# RUN apt-get install -y vim
# RUN python3 -c 'import faiss; print(faiss.IndexFlatIP)'

WORKDIR /home/app/


