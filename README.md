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
│   ├── toolchain/    # 交叉编译工具链
│   └── mkcommon.sh   # 主构建脚本
├── device/           # 设备配置
├── kernel/           # Linux 内核源码
│   └── linux-5.4/    # Linux 5.4 内核
├── rootfile/         # 根文件系统
├── tools/            # 打包和烧录工具
└── build.sh          # 主构建入口脚本
```

## 快速开始

### 环境要求

- Ubuntu 20.04+（推荐 22.04）
- 至少 20GB 可用磁盘空间

### 本地构建

```bash
# 1. 安装依赖
sudo apt-get update
sudo apt-get install -y build-essential git libncurses5-dev \
    libssl-dev bc bison flex u-boot-tools python3 python3-dev \
    python3-pip swig device-tree-compiler cpio gawk wget unzip \
    dosfstools mtools kmod rsync fakeroot

# 2. 配置
chmod +x build.sh
echo -e "1\n1\n0\n0\n0" | ./build.sh config

# 3. 编译 bootloader
./build.sh bootloader

# 4. 编译内核
./build.sh kernel

# 5. 打包固件
./build.sh pack
```

固件输出：`out/pack_out/` 目录

### GitHub Actions 编译

本项目支持 CI 自动编译 bootloader 和内核：

1. Fork 本仓库
2. 进入 Actions 页面
3. 选择 "Build Longan H618 Firmware"
4. 点击 "Run workflow"
5. 等待编译完成，下载产物

> **注意**：CI 只编译 bootloader 和内核，固件打包需要在本地执行 `./build.sh pack`。

## 使用 CI 产物打包固件

CI 编译产物位于 Releases 页面，包含：
- `u-boot-sun50iw9p1.bin` - Bootloader
- `Image.gz` - 内核镜像
- `sunxi.dtb` - 设备树
- `rootfs.ext4` - 根文件系统
- `rootfs.cpio.gz` - initramfs

本地打包步骤：

```bash
# 1. 克隆仓库
git clone https://github.com/JasonYANG170/Mini-LinuxPC-Pro.git
cd Mini-LinuxPC-Pro

# 2. 下载 CI 产物（从 Release 页面下载）
# 将 u-boot-sun50iw9p1.bin 放到 device/config/chips/h618/bin/
# 将 rootfs.ext4 放到 test/dragonboard/
# 将 rootfs.cpio.gz 放到 kernel/linux-5.4/

# 3. 配置（如果还没配置过）
echo -e "1\n1\n0\n0\n0" | ./build.sh config

# 4. 打包固件
./build.sh pack

# 固件输出：out/pack_out/*.img
```

## 已有功能

- 支持 ST7789V LCD 显示屏
- 支持双屏显示配置

## 许可证

本项目基于 Allwinner Longan SDK，请遵循相关许可协议。
