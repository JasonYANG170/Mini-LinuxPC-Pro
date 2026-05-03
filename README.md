# Longan H618

Allwinner H618 SoC 的 Linux BSP 构建系统，基于 Longan SDK。

## 硬件信息

- **SoC**: Allwinner H618 (ARM Cortex-A53, 四核)
- **架构**: ARM64 (aarch64)
- **内核**: Linux 5.4
- **开发板**: P1

## 项目结构

```
longan-h618/
├── brandy/           # Bootloader (U-Boot) 源码
├── build/            # 构建系统脚本和工具链
│   ├── toolchain/    # 交叉编译工具链 (LFS 管理)
│   ├── envsetup.sh   # 环境设置脚本
│   └── mkcommon.sh   # 主构建脚本
├── device/           # 设备配置
│   └── config/       # 芯片和板级配置
├── kernel/           # Linux 内核源码
│   └── linux-5.4/    # Linux 5.4 内核
├── rootfile/         # 根文件系统 (LFS 管理)
├── tools/            # 打包和烧录工具
├── build.sh          # 主构建入口脚本
└── docker-compose.yml
```

## 快速开始

### 环境要求

- Ubuntu 20.04+ 或其他 Linux 发行版
- Git LFS (用于大文件管理)
- 至少 20GB 可用磁盘空间

### 使用 Docker 构建 (推荐)

```bash
# 构建 Docker 镜像
docker-compose build

# 进入构建环境
docker-compose run --rm longan-build

# 在容器内执行构建
./build.sh
```

### 本地构建

```bash
# 1. 安装依赖
sudo apt-get update
sudo apt-get install -y build-essential git git-lfs libncurses5-dev \
    libssl-dev bc bison flex u-boot-tools python3 python3-dev \
    python3-pip swig device-tree-compiler cpio gawk wget unzip \
    dosfstools mtools kmod rsync

# 2. 初始化 Git LFS
git lfs install
git lfs pull

# 3. 解压工具链
cd build/toolchain
for f in *.tar.xz *.tar.bz2; do
    [ -f "$f" ] && tar -xf "$f"
done
cd ../..

# 4. 设置环境变量
export PATH="$(pwd)/build/toolchain/gcc-linaro-5.3.1-2016.05-x86_64_aarch64-linux-gnu/bin:$PATH"
export CROSS_COMPILE=aarch64-linux-gnu-
export ARCH=arm64

# 5. 执行构建
./build.sh
```

## 构建产物

构建输出位于 `out/` 目录：

- `out/h618/p1/dragonboard/` - 构建中间文件
- `out/pack_out/` - 打包后的固件镜像

## 配置说明

构建配置通过 `.buildconfig` 文件管理（自动生成，不纳入版本控制）。主要配置项：

| 变量 | 说明 | 默认值 |
|------|------|--------|
| LICHEE_IC | 芯片型号 | h618 |
| LICHEE_BOARD | 开发板 | p1 |
| LICHEE_PLATFORM | 平台 | linux |
| LICHEE_ARCH | 架构 | arm64 |
| LICHEE_KERN_VER | 内核版本 | linux-5.4 |

## 已有功能

- 支持 ST7789V LCD 显示屏
- 支持双屏显示配置
- 支持 Docker 容器化构建
- Git LFS 管理大型二进制文件

## 许可证

本项目基于 Allwinner Longan SDK，请遵循相关许可协议。
