FROM ubuntu:20.04

LABEL maintainer="Longan H618 Build Environment"
LABEL description="Docker image for building Allwinner H618 firmware"

# 避免交互式提示
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Shanghai

# 安装构建依赖
RUN apt-get update && apt-get install -y \
    build-essential \
    git \
    libncurses5-dev \
    libssl-dev \
    bc \
    bison \
    flex \
    u-boot-tools \
    python3 \
    python3-dev \
    python3-pip \
    swig \
    device-tree-compiler \
    libpython3-dev \
    cpio \
    gawk \
    wget \
    unzip \
    dosfstools \
    mtools \
    kmod \
    rsync \
    vim \
    sudo \
    && rm -rf /var/lib/apt/lists/*

# 下载并安装工具链
RUN mkdir -p /opt/toolchain && \
    cd /opt/toolchain && \
    wget -q https://releases.linaro.org/components/toolchain/binaries/5.3-2016.05/aarch64-linux-gnu/gcc-linaro-5.3.1-2016.05-x86_64_aarch64-linux-gnu.tar.xz && \
    tar -xf gcc-linaro-5.3.1-2016.05-x86_64_aarch64-linux-gnu.tar.xz && \
    rm gcc-linaro-5.3.1-2016.05-x86_64_aarch64-linux-gnu.tar.xz

# 设置环境变量
ENV PATH="/opt/toolchain/gcc-linaro-5.3.1-2016.05-x86_64_aarch64-linux-gnu/bin:${PATH}"
ENV CROSS_COMPILE=aarch64-linux-gnu-
ENV ARCH=arm64

# 创建工作目录
WORKDIR /workspace

# 复制源码
COPY . /workspace/

# 设置构建脚本权限
RUN chmod +x /workspace/build.sh

# 默认命令
CMD ["/bin/bash"]
