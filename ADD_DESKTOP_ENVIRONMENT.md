# 为 H618 添加桌面环境指南

## 问题分析

当前编译的镜像使用的是基础 rootfs (`target-arm64-linaro-5.3.tar.bz2`)，只包含基本的命令行工具，不包含桌面环境。

## 解决方案

有三种方法可以添加桌面环境：

### 方案 1: 使用更完整的 rootfs（已配置）✅

修改 `BoardConfig.mk` 使用更新的 rootfs。

**已完成的修改**：
```makefile
# device/config/chips/h618/configs/p1/dragonboard/BoardConfig.mk
LICHEE_ROOTFS:=target-arm64-10.3.tar.bz2
```

这个 rootfs 包含更多工具，但仍然是命令行系统。

### 方案 2: 手动安装桌面环境（推荐）

在现有系统上手动安装桌面环境。

#### 2.1 准备工作

```bash
# 启动系统后，配置网络
ifconfig eth0 up
udhcpc -i eth0

# 或使用静态 IP
ifconfig eth0 192.168.1.100 netmask 255.255.255.0
route add default gw 192.168.1.1
echo "nameserver 8.8.8.8" > /etc/resolv.conf
```

#### 2.2 安装桌面环境选项

##### 选项 A: 轻量级桌面 - XFCE (推荐)

```bash
# 如果系统支持 apt/opkg
opkg update
opkg install xorg-server xf86-video-fbdev
opkg install xfce4 xfce4-terminal
opkg install lightdm  # 显示管理器

# 启动桌面
startxfce4
```

##### 选项 B: 更轻量 - LXDE

```bash
opkg update
opkg install xorg-server xf86-video-fbdev
opkg install lxde-core lxterminal
opkg install lxdm  # 显示管理器

# 启动桌面
startlxde
```

##### 选项 C: 最轻量 - Openbox + tint2

```bash
opkg update
opkg install xorg-server xf86-video-fbdev
opkg install openbox tint2 pcmanfm lxterminal
opkg install feh  # 壁纸

# 创建启动脚本
cat > ~/.xinitrc << 'EOF'
#!/bin/sh
tint2 &
pcmanfm --desktop &
exec openbox-session
EOF

chmod +x ~/.xinitrc

# 启动桌面
startx
```

##### 选项 D: Wayland - Weston (现代化)

```bash
opkg update
opkg install weston weston-examples

# 启动 Weston
weston --backend=fbdev-backend.so
```

#### 2.3 配置 X11 使用 Framebuffer

创建 `/etc/X11/xorg.conf.d/20-fbdev.conf`:
```
Section "Device"
    Identifier  "HDMI Framebuffer"
    Driver      "fbdev"
    Option      "fbdev" "/dev/fb1"
    Option      "ShadowFB" "off"
EndSection

Section "Monitor"
    Identifier  "HDMI Monitor"
EndSection

Section "Screen"
    Identifier  "HDMI Screen"
    Device      "HDMI Framebuffer"
    Monitor     "HDMI Monitor"
    DefaultDepth 24
    SubSection "Display"
        Depth 24
        Modes "1920x1080"
    EndSubSection
EndSection
```

#### 2.4 设置开机自动启动桌面

```bash
# 方法 1: 使用 .profile
cat >> /root/.profile << 'EOF'
if [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
    startx
fi
EOF

# 方法 2: 使用 systemd (如果支持)
systemctl set-default graphical.target

# 方法 3: 修改 inittab
# 编辑 /etc/inittab，添加：
# tty1::respawn:/usr/bin/startx
```

### 方案 3: 使用 Buildroot 构建完整系统

这是最灵活但最复杂的方法。

#### 3.1 配置 Buildroot

```bash
# 进入 buildroot 目录
cd buildroot/buildroot-201902  # 或其他版本

# 配置
make menuconfig
```

#### 3.2 在 menuconfig 中选择

```
Target packages --->
    Graphic libraries and applications (graphic/text) --->
        [*] X.org X Window System
            X11R7 Servers --->
                [*] xorg-server
            X11R7 Drivers --->
                [*] xf86-video-fbdev
        [*] Desktop environments --->
            [*] XFCE4
            或
            [*] LXDE
```

#### 3.3 编译

```bash
# 在 longan 根目录
./build.sh

# 或只编译 buildroot
./build.sh buildroot
```

#### 3.4 打包

```bash
cd build
./pack
```

### 方案 4: 使用预编译的桌面 rootfs

如果有预编译的包含桌面的 rootfs，可以直接使用。

#### 4.1 创建自定义 rootfs

```bash
# 在开发机上
mkdir -p custom-rootfs
cd custom-rootfs

# 解压基础 rootfs
tar -xjf ../device/config/rootfs_tar/target-arm64-10.3.tar.bz2

# 安装桌面环境（使用 qemu-aarch64-static 或交叉编译）
# ... 安装过程 ...

# 打包
tar -cjf target-arm64-desktop.tar.bz2 ./*

# 复制到 rootfs_tar 目录
cp target-arm64-desktop.tar.bz2 ../device/config/rootfs_tar/
```

#### 4.2 修改 BoardConfig

```makefile
LICHEE_ROOTFS:=target-arm64-desktop.tar.bz2
```

## 快速测试方案（不需要重新编译）

如果你已经有运行的系统，可以快速测试桌面环境：

### 1. 最小化 X11 测试

```bash
# 安装最小 X11
opkg update
opkg install xorg-server xf86-video-fbdev xterm

# 创建 .xinitrc
cat > ~/.xinitrc << 'EOF'
#!/bin/sh
xterm &
exec twm
EOF

chmod +x ~/.xinitrc

# 启动
startx
```

### 2. 使用 Matchbox (嵌入式桌面)

```bash
opkg install matchbox-window-manager matchbox-panel matchbox-desktop
opkg install xorg-server xf86-video-fbdev

cat > ~/.xinitrc << 'EOF'
#!/bin/sh
matchbox-panel &
matchbox-desktop &
exec matchbox-window-manager
EOF

startx
```

### 3. 使用 Weston (Wayland)

```bash
# 安装 Weston
opkg install weston

# 配置
mkdir -p ~/.config
cat > ~/.config/weston.ini << 'EOF'
[core]
backend=fbdev-backend.so
require-input=false

[output]
name=fb1
mode=1920x1080

[shell]
background-color=0xff002244
panel-position=top
EOF

# 启动
weston
```

## 推荐的桌面环境对比

| 桌面环境 | 内存占用 | 性能 | 功能 | 适用场景 |
|---------|---------|------|------|---------|
| XFCE4 | ~200MB | 中等 | 完整 | 日常使用 |
| LXDE | ~150MB | 较好 | 完整 | 资源受限 |
| Openbox | ~100MB | 很好 | 基础 | 极简环境 |
| Matchbox | ~80MB | 最好 | 基础 | 嵌入式 |
| Weston | ~120MB | 很好 | 现代 | 触摸屏 |

## 验证桌面环境

### 检查 X11 是否工作

```bash
# 检查 X server
ps aux | grep X

# 检查显示
echo $DISPLAY  # 应该显示 :0 或类似

# 测试显示
xdpyinfo
xrandr
```

### 检查 Framebuffer

```bash
# 确认 fb1 (HDMI) 可用
fbset -fb /dev/fb1

# 测试显示
cat /dev/urandom > /dev/fb1
```

## 故障排查

### X11 无法启动

```bash
# 查看日志
cat /var/log/Xorg.0.log

# 常见问题：
# 1. 缺少 fbdev 驱动
opkg install xf86-video-fbdev

# 2. 权限问题
chmod 666 /dev/fb1
chmod 666 /dev/tty*

# 3. 配置问题
# 删除 /etc/X11/xorg.conf 使用自动检测
```

### Weston 无法启动

```bash
# 查看错误
weston --backend=fbdev-backend.so --log=/tmp/weston.log

# 检查 framebuffer
ls -l /dev/fb*

# 设置环境变量
export XDG_RUNTIME_DIR=/tmp
```

### 显示器无信号

```bash
# 检查 HDMI 连接
cat /sys/class/drm/card0-HDMI-A-1/status

# 检查分辨率
fbset -fb /dev/fb1

# 强制设置分辨率
fbset -fb /dev/fb1 -g 1920 1080 1920 1080 32
```

## 性能优化

### 1. 禁用不需要的服务

```bash
# 禁用 console 在 HDMI 上
# 修改启动参数: fbcon=map:1 (只在 ST7789 显示)
```

### 2. 使用硬件加速

```bash
# 如果支持 Mali GPU
opkg install mali-driver
export FRAMEBUFFER=/dev/fb1
```

### 3. 优化 X11 配置

```
Section "Device"
    Option "AccelMethod" "none"  # 或 "exa"
    Option "ShadowFB" "off"
EndSection
```

## 完整示例：安装 XFCE4

```bash
#!/bin/bash

# 1. 配置网络
ifconfig eth0 up
udhcpc -i eth0

# 2. 更新包管理器
opkg update

# 3. 安装 X11 基础
opkg install xorg-server xf86-video-fbdev xf86-input-evdev

# 4. 安装 XFCE4
opkg install xfce4 xfce4-terminal thunar

# 5. 安装显示管理器
opkg install lightdm

# 6. 配置 X11
mkdir -p /etc/X11/xorg.conf.d
cat > /etc/X11/xorg.conf.d/20-fbdev.conf << 'EOF'
Section "Device"
    Identifier  "HDMI"
    Driver      "fbdev"
    Option      "fbdev" "/dev/fb1"
EndSection
EOF

# 7. 启动桌面
startxfce4

# 或设置开机自启动
systemctl enable lightdm
systemctl start lightdm
```

## 总结

1. **最快方案**: 使用方案 2 手动安装（推荐 Weston 或 Matchbox）
2. **最完整方案**: 使用方案 3 Buildroot 构建
3. **当前配置**: 已修改为使用 `target-arm64-10.3.tar.bz2`，包含更多工具

重新编译后，你可以在系统中手动安装桌面环境，或者使用 Buildroot 构建包含桌面的完整系统。
