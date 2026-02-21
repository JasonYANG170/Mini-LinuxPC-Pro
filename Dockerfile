FROM ubuntu:latest

LABEL maintainer="Longan H618 Build Environment"
LABEL description="Docker image for building Allwinner H618 firmware"

# 避免交互式提示
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Shanghai

# 安装构建依赖和 Git LFS
RUN apt-get update && apt-get install -y \
    build-essential \
    git \
    git-lfs \
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
    && ln -sf /usr/bin/python3 /usr/bin/python \
    && rm -rf /var/lib/apt/lists/*

# 创建工作目录
WORKDIR /workspace

# 复制源码（包含 LFS 文件）
COPY . /workspace/

# 初始化 Git LFS 并拉取大文件
RUN git lfs install && \
    if [ -d .git ]; then git lfs pull; fi

# 解压工具链
RUN cd /workspace/build/toolchain && \
    for f in *.tar.xz *.tar.bz2; do \
        if [ -f "$f" ]; then \
            echo "Extracting $f..." && \
            tar -xf "$f"; \
        fi \
    done

# 设置环境变量（根据实际工具链路径调整）
ENV PATH="/workspace/build/toolchain/gcc-linaro-5.3.1-2016.05-x86_64_aarch64-linux-gnu/bin:${PATH}"
ENV CROSS_COMPILE=aarch64-linux-gnu-
ENV ARCH=arm64

# 设置构建脚本权限
RUN chmod +x /workspace/build.sh

# 默认命令
CMD ["/bin/bash"]
