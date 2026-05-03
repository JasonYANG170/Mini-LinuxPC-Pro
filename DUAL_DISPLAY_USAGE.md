# H618 双显示使用指南

## 当前配置状态

✅ **HDMI (fb0)**: 1920x1080 - 主显示  
✅ **ST7789 (fb1)**: 320x170 - 辅助显示  
✅ **Console 映射**: `fbcon=map:01` - 两个屏幕都显示 console

## 显示效果

### 启动阶段
```
┌─────────────────────────────────────┐
│  HDMI (1920x1080)                   │
│  ┌─────────────────────────────┐   │
│  │ U-Boot Logo                  │   │
│  │ Kernel Boot Messages         │   │
│  │ System Console               │   │
│  └─────────────────────────────┘   │
└─────────────────────────────────────┘

┌──────────────────┐
│ ST7789 (320x170) │
│ ┌──────────────┐ │
│ │ Boot Msgs    │ │
│ │ Console      │ │
│ └──────────────┘ │
└──────────────────┘
```

### 运行阶段
- **HDMI**: 可以运行桌面环境 (X11/Wayland) 或显示 console
- **ST7789**: 显示 console 或自定义状态信息

## 快速测试

### 1. 编译和烧录
```bash
# 编译固件
./build.sh

# 打包
cd build && ./pack

# 烧录到设备
# (使用你的烧录工具)
```

### 2. 启动后验证

#### 检查 Framebuffer 设备
```bash
# 列出所有 framebuffer
ls -l /dev/fb*

# 应该看到：
# /dev/fb0 -> HDMI
# /dev/fb1 -> ST7789

# 查看设备信息
cat /sys/class/graphics/fb0/name
cat /sys/class/graphics/fb0/modes

cat /sys/class/graphics/fb1/name
cat /sys/class/graphics/fb1/modes
```

#### 查看分辨率
```bash
# 安装 fbset (如果没有)
apt-get install fbset

# 查看 HDMI
fbset -fb /dev/fb0

# 查看 ST7789
fbset -fb /dev/fb1
```

### 3. 测试显示

#### 测试 HDMI (fb0)
```bash
# 清屏 - 黑色
cat /dev/zero > /dev/fb0

# 白色
dd if=/dev/zero bs=1M count=8 | tr '\000' '\377' > /dev/fb0

# 随机彩色图案
cat /dev/urandom > /dev/fb0

# 停止 (Ctrl+C)
```

#### 测试 ST7789 (fb1)
```bash
# 清屏 - 黑色
cat /dev/zero > /dev/fb1

# 白色
dd if=/dev/zero bs=1k count=200 | tr '\000' '\377' > /dev/fb1

# 随机彩色图案
cat /dev/urandom > /dev/fb1

# 停止 (Ctrl+C)
```

#### 测试 Console 输出
```bash
# 在两个屏幕上都会显示
echo "Hello Dual Display!" > /dev/tty1

# 清屏
clear > /dev/tty1

# 显示系统信息
uname -a > /dev/tty1
date > /dev/tty1
```

## 使用场景

### 场景 1: HDMI 桌面 + ST7789 状态监控

#### 启动桌面环境 (HDMI)
```bash
# 启动 X11 (会使用 fb0/HDMI)
startx

# 或者启动 Wayland
weston --backend=fbdev-backend.so
```

#### ST7789 显示系统状态
创建状态监控脚本：
```bash
cat > /usr/local/bin/lcd-monitor.sh << 'EOF'
#!/bin/bash

# 设置小字体
setfont /usr/share/consolefonts/Lat15-Terminus12x6.psf.gz 2>/dev/null

while true; do
  clear > /dev/tty1
  
  echo "╔══════════════════╗" > /dev/tty1
  echo "║ System Monitor   ║" > /dev/tty1
  echo "╠══════════════════╣" > /dev/tty1
  
  # 时间
  echo "║ $(date +%Y-%m-%d)   ║" > /dev/tty1
  echo "║ $(date +%H:%M:%S)       ║" > /dev/tty1
  echo "╟──────────────────╢" > /dev/tty1
  
  # CPU 使用率
  CPU=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
  printf "║ CPU: %5.1f%%      ║\n" "$CPU" > /dev/tty1
  
  # 内存使用
  MEM=$(free | grep Mem | awk '{printf "%.0f", $3/$2 * 100}')
  printf "║ MEM: %5s%%      ║\n" "$MEM" > /dev/tty1
  
  # 温度 (如果可用)
  if [ -f /sys/class/thermal/thermal_zone0/temp ]; then
    TEMP=$(cat /sys/class/thermal/thermal_zone0/temp)
    TEMP=$((TEMP/1000))
    printf "║ TEMP: %3d°C      ║\n" "$TEMP" > /dev/tty1
  fi
  
  # 运行时间
  UPTIME=$(uptime -p | sed 's/up //')
  echo "║ Up: $UPTIME" > /dev/tty1
  
  echo "╚══════════════════╝" > /dev/tty1
  
  sleep 2
done
EOF

chmod +x /usr/local/bin/lcd-monitor.sh
```

#### 设置开机自启动
```bash
cat > /etc/systemd/system/lcd-monitor.service << 'EOF'
[Unit]
Description=LCD Status Monitor
After=multi-user.target

[Service]
Type=simple
ExecStart=/usr/local/bin/lcd-monitor.sh
StandardOutput=tty
TTYPath=/dev/tty1
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable lcd-monitor.service
systemctl start lcd-monitor.service
```

### 场景 2: 双屏显示相同内容

当前配置 `fbcon=map:01` 已经实现了这个功能：
- 启动信息在两个屏幕都显示
- Console 输出在两个屏幕都显示
- 适合调试和演示

### 场景 3: HDMI 显示应用，ST7789 显示日志

#### 在 HDMI 上运行应用
```bash
# 使用 fb0
FRAMEBUFFER=/dev/fb0 your_application
```

#### ST7789 显示实时日志
```bash
# 方法 1: 直接输出到 tty1
tail -f /var/log/syslog > /dev/tty1

# 方法 2: 使用 screen/tmux
screen -S lcd /dev/tty1
# 然后在 screen 中运行命令

# 方法 3: 自定义日志监控
cat > /usr/local/bin/lcd-logs.sh << 'EOF'
#!/bin/bash
while true; do
  clear > /dev/tty1
  echo "=== Recent Logs ===" > /dev/tty1
  tail -20 /var/log/syslog > /dev/tty1
  sleep 5
done
EOF

chmod +x /usr/local/bin/lcd-logs.sh
/usr/local/bin/lcd-logs.sh &
```

### 场景 4: 只在 ST7789 显示 Console

如果你想让 HDMI 完全用于图形界面，ST7789 专门显示 console：

修改启动参数：
```bash
# 编辑 env.cfg，将 fbcon=map:01 改为 fbcon=map:10
# 这样 console 只在 fb1 (ST7789) 显示
```

## 桌面环境配置

### X11 配置

创建 `/etc/X11/xorg.conf.d/20-fbdev.conf`:
```
Section "Device"
    Identifier  "HDMI Display"
    Driver      "fbdev"
    Option      "fbdev" "/dev/fb0"
EndSection

Section "Monitor"
    Identifier  "HDMI Monitor"
    Option      "PreferredMode" "1920x1080"
EndSection

Section "Screen"
    Identifier  "HDMI Screen"
    Device      "HDMI Display"
    Monitor     "HDMI Monitor"
    DefaultDepth 24
    SubSection "Display"
        Depth 24
        Modes "1920x1080"
    EndSubSection
EndSection
```

### Weston (Wayland) 配置

创建 `/etc/weston.ini`:
```ini
[core]
backend=fbdev-backend.so
require-input=false

[output]
name=fb0
mode=1920x1080@60
transform=normal

[shell]
background-image=/usr/share/backgrounds/default.png
background-type=scale-crop
panel-position=top
```

### 启动桌面
```bash
# X11
startx

# Weston
weston --backend=fbdev-backend.so

# 或者设置开机自启动
systemctl set-default graphical.target
```

## 高级功能

### 1. 在 ST7789 上显示图片

```bash
# 安装 fbi (framebuffer image viewer)
apt-get install fbi

# 显示图片到 ST7789
fbi -d /dev/fb1 -T 1 -noverbose -a /path/to/image.jpg

# 显示图片到 HDMI
fbi -d /dev/fb0 -T 1 -noverbose -a /path/to/image.jpg
```

### 2. 在 ST7789 上播放视频

```bash
# 安装 mplayer
apt-get install mplayer

# 播放视频到 ST7789
mplayer -vo fbdev2:/dev/fb1 -zoom -x 320 -y 170 video.mp4

# 播放视频到 HDMI
mplayer -vo fbdev2:/dev/fb0 video.mp4
```

### 3. 使用 Python 控制显示

```python
#!/usr/bin/env python3
import os

def write_to_lcd(text):
    """在 ST7789 上显示文本"""
    with open('/dev/tty1', 'w') as f:
        f.write('\033[2J')  # 清屏
        f.write('\033[H')   # 光标回到开头
        f.write(text)

def clear_lcd():
    """清空 ST7789"""
    with open('/dev/tty1', 'w') as f:
        f.write('\033[2J')

# 使用示例
write_to_lcd("Hello from Python!\n")
write_to_lcd("Temperature: 45°C\n")
write_to_lcd("CPU: 25%\n")
```

### 4. 调整 Console 字体

```bash
# 列出可用字体
ls /usr/share/consolefonts/

# 小字体 (适合 ST7789)
setfont /usr/share/consolefonts/Lat15-Terminus12x6.psf.gz

# 更小的字体
setfont /usr/share/consolefonts/Lat15-Terminus10x5.psf.gz

# 永久设置
cat >> /etc/rc.local << 'EOF'
setfont /usr/share/consolefonts/Lat15-Terminus12x6.psf.gz
EOF
```

### 5. 虚拟终端切换

```bash
# 切换到 tty1 (ST7789 会显示)
chvt 1

# 切换到 tty2
chvt 2

# 切换回图形界面 (通常是 tty7)
chvt 7

# 查看当前 tty
tty
```

## 故障排查

### HDMI 不显示

```bash
# 1. 检查 HDMI 连接
# 2. 查看内核日志
dmesg | grep -i hdmi
dmesg | grep -i disp

# 3. 检查 framebuffer
cat /sys/class/graphics/fb0/name
fbset -fb /dev/fb0

# 4. 测试显示
cat /dev/urandom > /dev/fb0

# 5. 检查 HDMI 热插拔
cat /sys/class/drm/card0-HDMI-A-1/status
```

### ST7789 不显示

```bash
# 1. 检查 SPI 设备
ls -l /dev/spidev*
dmesg | grep st7789
dmesg | grep spi

# 2. 检查 framebuffer
cat /sys/class/graphics/fb1/name
fbset -fb /dev/fb1

# 3. 测试显示
cat /dev/urandom > /dev/fb1

# 4. 检查设备树
cat /proc/device-tree/soc/spi@*/st7789v@*/compatible
```

### Console 不显示在 ST7789

```bash
# 1. 检查启动参数
cat /proc/cmdline | grep fbcon

# 2. 检查 console 映射
cat /sys/class/graphics/fbcon/cursor_blink

# 3. 手动输出测试
echo "Test" > /dev/tty1

# 4. 检查 tty 设备
ls -l /dev/tty*
```

### 字体太大或太小

```bash
# 查看当前字体
showconsolefont

# 更改字体
dpkg-reconfigure console-setup

# 或手动设置
setfont /usr/share/consolefonts/Lat15-Terminus12x6.psf.gz
```

## 性能优化

### 减少 Console 刷新

```bash
# 在启动参数中添加
consoleblank=0  # 禁用屏幕保护
vt.global_cursor_default=0  # 禁用光标闪烁
```

### 调整 Framebuffer 性能

```bash
# 启用 DMA 加速 (如果支持)
echo 1 > /sys/module/fbtft_device/parameters/dma

# 调整刷新率
fbset -fb /dev/fb1 -vyres 340  # 双缓冲
```

## 配置文件位置

- 设备树: `device/config/chips/h618/configs/p1/board.dts`
- 启动参数: `device/config/chips/h618/configs/p1/dragonboard/env.cfg`
- 内核配置: `kernel/linux-5.4/arch/arm64/configs/linux_h618_defconfig`

## 总结

当前配置实现了：
- ✅ HDMI 和 ST7789 同时显示 console
- ✅ HDMI 可以运行桌面环境
- ✅ ST7789 可以显示状态信息
- ✅ 灵活的显示控制

需要修改显示模式时，只需调整 `fbcon=map:XX` 参数：
- `map:1` - 只 HDMI
- `map:10` - 只 ST7789  
- `map:01` - 两个都显示 (当前配置)
