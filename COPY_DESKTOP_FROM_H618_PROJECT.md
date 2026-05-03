# 从 H618-20230427-v1.1 项目复制桌面环境

## 发现

在 `~/H618-20230427-v1.1/longan-h618/` 项目中发现了预编译的桌面 rootfs：

```bash
rootfile/rootfs-ds-hx1x-desktop-2025-12-09.tar  (1.9GB)
rootfile/rootfs-ds-hx1x-server-2025-12-09.tar.gz (376MB)
```

这个桌面 rootfs 包含完整的 **XFCE4 桌面环境**！

## 桌面 rootfs 内容

通过检查发现包含：
- X11 服务器
- XFCE4 桌面环境
- 完整的桌面应用程序
- 显示管理器

```bash
# 包含的关键文件
usr/bin/startx
usr/bin/startxfce4
usr/bin/X
usr/bin/xfce4-terminal
usr/bin/xfce4-session
usr/share/xsessions/xfce.desktop
usr/share/xsessions/ubuntu-xorg.desktop
```

## 解决方案：复制桌面 rootfs

### 方法 1: 直接复制 tar 文件（推荐）

```bash
# 1. 复制桌面 rootfs 到当前项目
cp ~/H618-20230427-v1.1/longan-h618/rootfile/rootfs-ds-hx1x-desktop-2025-12-09.tar \
   ~/longan-h618/device/config/rootfs_tar/

# 2. 重命名为标准格式
cd ~/longan-h618/device/config/rootfs_tar/
mv rootfs-ds-hx1x-desktop-2025-12-09.tar target-arm64-desktop.tar

# 3. 压缩（可选，节省空间）
tar -cjf target-arm64-desktop.tar.bz2 -C /tmp extracted_rootfs/
# 或者直接压缩 tar
bzip2 target-arm64-desktop.tar
# 这会生成 target-arm64-desktop.tar.bz2

# 4. 修改 BoardConfig.mk
# 编辑 device/config/chips/h618/configs/p1/dragonboard/BoardConfig.mk
# 添加：
LICHEE_ROOTFS:=target-arm64-desktop.tar.bz2
```

### 方法 2: 解压、检查、重新打包

```bash
# 1. 创建临时目录
mkdir -p /tmp/desktop-rootfs
cd /tmp/desktop-rootfs

# 2. 解压桌面 rootfs
tar -xf ~/H618-20230427-v1.1/longan-h618/rootfile/rootfs-ds-hx1x-desktop-2025-12-09.tar

# 3. 检查内容
ls -la rootfs/
ls rootfs/usr/bin/ | grep xfce
ls rootfs/usr/share/xsessions/

# 4. 可选：添加自定义内容
# 例如：添加你的应用程序、配置文件等

# 5. 重新打包
cd /tmp/desktop-rootfs
tar -cjf target-arm64-desktop.tar.bz2 rootfs/

# 6. 复制到项目
cp target-arm64-desktop.tar.bz2 ~/longan-h618/device/config/rootfs_tar/

# 7. 修改 BoardConfig.mk
```

### 方法 3: 直接使用原始 tar（最快）

```bash
# 1. 复制并重命名
cp ~/H618-20230427-v1.1/longan-h618/rootfile/rootfs-ds-hx1x-desktop-2025-12-09.tar \
   ~/longan-h618/device/config/rootfs_tar/target-arm64-desktop.tar

# 2. 修改 BoardConfig.mk
cat >> ~/longan-h618/device/config/chips/h618/configs/p1/dragonboard/BoardConfig.mk << 'EOF'
LICHEE_ROOTFS:=target-arm64-desktop.tar
EOF
```

## 修改 BoardConfig.mk

编辑 `device/config/chips/h618/configs/p1/dragonboard/BoardConfig.mk`:

```makefile
LICHEE_KERN_DEFCONF := sun50iw9p1smp_h618_dragonboard_defconfig
LICHEE_KERN_VER := 5.4
LICHEE_BRANDY_VER:=2.0
LICHEE_BRANDY_DEFCONF:=sun50iw9p1_android11_defconfig
LICHEE_ROOTFS:=target-arm64-desktop.tar
```

或者如果压缩了：
```makefile
LICHEE_ROOTFS:=target-arm64-desktop.tar.bz2
```

## 构建系统如何使用 rootfs

根据 `build/mkcmd.sh` 的代码：

```bash
# 构建系统会：
1. 读取 LICHEE_ROOTFS 变量
2. 从 device/config/rootfs_tar/ 目录查找对应的 tar 文件
3. 解压到 out/h618/p1/dragonboard/rootfs/
4. 复制内核模块到 rootfs/lib/modules/
5. 打包成 rootfs.squashfs
6. 最终打包到固件中
```

## 完整操作步骤

```bash
#!/bin/bash

# 1. 复制桌面 rootfs
echo "复制桌面 rootfs..."
cp ~/H618-20230427-v1.1/longan-h618/rootfile/rootfs-ds-hx1x-desktop-2025-12-09.tar \
   ~/longan-h618/device/config/rootfs_tar/target-arm64-desktop.tar

# 2. 检查文件大小
ls -lh ~/longan-h618/device/config/rootfs_tar/target-arm64-desktop.tar

# 3. 修改 BoardConfig.mk
echo "修改 BoardConfig.mk..."
cat > ~/longan-h618/device/config/chips/h618/configs/p1/dragonboard/BoardConfig.mk << 'EOF'
LICHEE_KERN_DEFCONF := sun50iw9p1smp_h618_dragonboard_defconfig
LICHEE_KERN_VER := 5.4
LICHEE_BRANDY_VER:=2.0
LICHEE_BRANDY_DEFCONF:=sun50iw9p1_android11_defconfig
LICHEE_ROOTFS:=target-arm64-desktop.tar
EOF

# 4. 清理旧的构建输出（可选）
echo "清理旧输出..."
rm -rf ~/longan-h618/out/h618/p1/dragonboard/rootfs

# 5. 重新配置
echo "重新配置..."
cd ~/longan-h618
./build.sh config

# 6. 编译
echo "开始编译..."
./build.sh

# 7. 打包
echo "打包固件..."
cd build
./pack

echo "完成！固件位于 out/pack_out/"
```

## 验证桌面 rootfs 内容

在复制之前，可以先验证内容：

```bash
# 列出桌面相关文件
tar -tf ~/H618-20230427-v1.1/longan-h618/rootfile/rootfs-ds-hx1x-desktop-2025-12-09.tar | \
  grep -E "usr/bin/(startx|X|xfce)" | head -20

# 列出桌面会话文件
tar -tf ~/H618-20230427-v1.1/longan-h618/rootfile/rootfs-ds-hx1x-desktop-2025-12-09.tar | \
  grep "usr/share/xsessions"

# 检查是否包含必要的库
tar -tf ~/H618-20230427-v1.1/longan-h618/rootfile/rootfs-ds-hx1x-desktop-2025-12-09.tar | \
  grep -E "usr/lib.*libX|usr/lib.*libxfce"
```

## 桌面环境启动

烧录固件后，系统应该会自动启动桌面环境。如果没有：

```bash
# 手动启动 XFCE4
startxfce4

# 或使用 startx
startx

# 检查显示管理器
systemctl status lightdm
# 或
systemctl status gdm
```

## 配置 X11 使用正确的 Framebuffer

确保 X11 使用 fb1 (HDMI)：

```bash
# 创建配置文件
mkdir -p /etc/X11/xorg.conf.d
cat > /etc/X11/xorg.conf.d/20-fbdev.conf << 'EOF'
Section "Device"
    Identifier  "HDMI Display"
    Driver      "fbdev"
    Option      "fbdev" "/dev/fb1"
EndSection

Section "Screen"
    Identifier  "HDMI Screen"
    Device      "HDMI Display"
    DefaultDepth 24
    SubSection "Display"
        Depth 24
        Modes "1920x1080"
    EndSubSection
EndSection
EOF
```

## 注意事项

### 1. 文件大小
桌面 rootfs 很大 (1.9GB)，确保有足够的磁盘空间：
- 源文件: 1.9GB
- 解压后: ~4-5GB
- 编译输出: 额外 2-3GB

### 2. 编译时间
由于 rootfs 很大，编译和打包时间会更长。

### 3. 固件大小
最终固件会比基础版本大很多，确保存储设备有足够空间。

### 4. 内存需求
XFCE4 桌面需要至少 512MB RAM，推荐 1GB+。

## 对比

| 项目 | 基础 rootfs | 桌面 rootfs |
|------|------------|------------|
| 大小 | 33MB | 1.9GB |
| 内容 | 命令行工具 | 完整桌面 |
| 内存 | ~50MB | ~200MB+ |
| 启动时间 | 快 | 较慢 |
| 用途 | 服务器/嵌入式 | 桌面应用 |

## 故障排查

### 问题：编译时找不到 rootfs

```bash
# 检查文件是否存在
ls -lh ~/longan-h618/device/config/rootfs_tar/target-arm64-desktop.tar

# 检查 BoardConfig.mk
cat ~/longan-h618/device/config/chips/h618/configs/p1/dragonboard/BoardConfig.mk | grep LICHEE_ROOTFS
```

### 问题：桌面无法启动

```bash
# 检查 X11 日志
cat /var/log/Xorg.0.log

# 检查 framebuffer
ls -l /dev/fb*
fbset -fb /dev/fb1

# 手动启动
startxfce4
```

### 问题：显示在错误的屏幕

```bash
# 确认 fbcon 映射
cat /proc/cmdline | grep fbcon

# 应该是 fbcon=map:01 或 fbcon=map:10
```

## 总结

通过复制 H618-20230427-v1.1 项目的桌面 rootfs，你可以快速获得一个包含完整 XFCE4 桌面环境的系统，无需手动安装或使用 Buildroot 构建。

这是最快速、最简单的方法！
