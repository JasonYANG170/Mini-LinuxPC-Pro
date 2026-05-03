# H618 双显示配置说明

## 配置目标
- **HDMI**: 主显示 - 显示桌面 GUI (fb0)
- **ST7789 (SPI LCD)**: 辅助显示 - 显示终端 console (fb1)

## 已完成的配置修改

### 1. 设备树配置 (board.dts)

#### Framebuffer 配置
```
fb0: HDMI - 1920x1080 (主显示/桌面)
fb1: ST7789 - 320x170 (辅助显示/终端)
```

#### 显示输出配置
```
screen0_output_type = 3  (HDMI)
screen1_output_type = 0  (禁用，ST7789 通过 SPI 独立驱动)
dev0_output_type = 3     (HDMI)
dev1_output_type = 0     (禁用)
```

### 2. 启动参数 (env.cfg)

#### Console 配置
```bash
console=ttyS0,115200 console=tty1 consoleblank=0
```
- `ttyS0` - 串口调试
- `tty1` - 虚拟终端（会显示在 ST7789 上）

#### Framebuffer Console 映射
```bash
fbcon=map:01
```
这个参数的含义：
- `map:01` = console 同时在 fb0 和 fb1 上显示
- 启动时 HDMI 会显示启动信息
- ST7789 也会显示终端信息
- 桌面环境启动后会接管 fb0 (HDMI)

### 3. Framebuffer 设备映射
- `/dev/fb0` → HDMI (1920x1080) - 主显示
- `/dev/fb1` → ST7789 (320x170) - 辅助显示

## 工作原理

### 启动阶段
```
┌─────────────────────────────────────┐
│  启动流程                            │
├─────────────────────────────────────┤
│  U-Boot Logo → HDMI                 │
│  内核启动信息 → HDMI + ST7789      │
│  终端 console → HDMI + ST7789      │
└─────────────────────────────────────┘
```

### 运行阶段
```
┌─────────────────────────────────────┐
│  正常运行                            │
├─────────────────────────────────────┤
│  桌面环境 (X11/Wayland) → HDMI      │
│  终端 tty1-6 → ST7789              │
│  串口调试 → ttyS0                   │
└─────────────────────────────────────┘
```

## 验证配置

### 1. 检查 framebuffer 设备
```bash
ls -l /dev/fb*
cat /sys/class/graphics/fb0/name  # 应该显示 disp (HDMI)
cat /sys/class/graphics/fb1/name  # 应该显示 fb_st7789v
```

### 2. 查看分辨率
```bash
fbset -fb /dev/fb0  # HDMI: 1920x1080
fbset -fb /dev/fb1  # ST7789: 320x170
```

### 3. 测试 HDMI 显示
```bash
# 清屏
cat /dev/zero > /dev/fb0

# 显示测试图案
cat /dev/urandom > /dev/fb0
```

### 4. 测试 ST7789 显示
```bash
# 清屏
cat /dev/zero > /dev/fb1

# 显示测试图案
cat /dev/urandom > /dev/fb1
```

### 5. 测试 console 输出
```bash
# 切换到 tty1 (应该在 ST7789 上显示)
chvt 1

# 输出测试信息
echo "Testing ST7789 console" > /dev/tty1

# 切换回图形界面
chvt 7
```

## 桌面环境配置

### 对于 X11
创建 `/etc/X11/xorg.conf.d/20-fbdev.conf`:
```
Section "Device"
    Identifier  "HDMI Framebuffer"
    Driver      "fbdev"
    Option      "fbdev" "/dev/fb0"
EndSection

Section "Screen"
    Identifier  "HDMI Screen"
    Device      "HDMI Framebuffer"
    DefaultDepth 24
    SubSection "Display"
        Depth 24
        Modes "1920x1080"
    EndSubSection
EndSection
```

### 对于 Wayland/Weston
编辑 `/etc/weston.ini`:
```ini
[core]
backend=fbdev-backend.so

[output]
name=fb0
mode=1920x1080
```

## 使用场景

### 场景 1: 桌面在 HDMI，监控信息在 ST7789
```bash
# 启动桌面环境（自动使用 fb0/HDMI）
startx

# 在 ST7789 上显示系统信息
while true; do
  clear > /dev/tty1
  echo "=== System Monitor ===" > /dev/tty1
  date > /dev/tty1
  uptime > /dev/tty1
  free -h > /dev/tty1
  sleep 5
done &
```

### 场景 2: 只使用 ST7789 作为状态显示
```bash
# 禁用 HDMI 上的 console（在启动参数中）
# 修改 fbcon=map:01 为 fbcon=map:10

# 然后 ST7789 独占 console
```

### 场景 3: 调试模式 - 两个屏幕都显示 console
```bash
# 当前配置 fbcon=map:01 就是这个模式
# HDMI 和 ST7789 都会显示相同的 console 内容
```

## 高级配置

### 调整 ST7789 的 console 字体大小
由于 ST7789 分辨率较小 (320x170)，建议使用小字体：
```bash
# 安装 console 字体工具
apt-get install kbd

# 列出可用字体
ls /usr/share/consolefonts/

# 设置较小的字体（推荐）
setfont /usr/share/consolefonts/Lat15-Terminus12x6.psf.gz

# 或者更小的字体
setfont /usr/share/consolefonts/Lat15-Terminus10x5.psf.gz

# 永久设置（编辑 /etc/default/console-setup）
FONTFACE="Terminus"
FONTSIZE="6x12"
```

### 在 ST7789 上显示自定义信息
```bash
# 创建状态显示脚本
cat > /usr/local/bin/lcd-status.sh << 'EOF'
#!/bin/bash
while true; do
  clear > /dev/tty1
  echo "╔════════════════════╗" > /dev/tty1
  echo "║  System Status     ║" > /dev/tty1
  echo "╠════════════════════╣" > /dev/tty1
  echo "║ $(date +%H:%M:%S)         ║" > /dev/tty1
  echo "║ CPU: $(top -bn1 | grep "Cpu(s)" | awk '{print $2}')%      ║" > /dev/tty1
  echo "║ Mem: $(free | grep Mem | awk '{printf "%.0f%%", $3/$2 * 100}')         ║" > /dev/tty1
  echo "╚════════════════════╝" > /dev/tty1
  sleep 2
done
EOF

chmod +x /usr/local/bin/lcd-status.sh

# 创建 systemd 服务
cat > /etc/systemd/system/lcd-status.service << 'EOF'
[Unit]
Description=LCD Status Display
After=multi-user.target

[Service]
Type=simple
ExecStart=/usr/local/bin/lcd-status.sh
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl enable lcd-status.service
systemctl start lcd-status.service
```

### 旋转 ST7789 显示
ST7789 已配置旋转 90 度（在设备树中）：
```
rotate = <90>;
```

如果需要其他旋转角度，修改为：
- `0` - 不旋转
- `90` - 顺时针 90 度
- `180` - 180 度
- `270` - 顺时针 270 度

## 故障排查

### 问题：HDMI 不显示
1. 检查 HDMI 连接和显示器
2. 查看内核日志：
```bash
dmesg | grep -i hdmi
dmesg | grep -i disp
```

3. 检查 framebuffer：
```bash
cat /sys/class/graphics/fb0/name
fbset -fb /dev/fb0
```

4. 检查启动参数：
```bash
cat /proc/cmdline | grep fbcon
# 应该看到 fbcon=map:01
```

### 问题：ST7789 没有显示
1. 检查 SPI 设备：
```bash
ls /dev/spidev*
dmesg | grep st7789
dmesg | grep spi
```

2. 检查 framebuffer：
```bash
cat /sys/class/graphics/fb1/name
fbset -fb /dev/fb1
```

3. 测试显示：
```bash
# 填充白色
dd if=/dev/zero bs=1024 count=100 | tr '\000' '\377' > /dev/fb1
```

### 问题：桌面环境无法启动
1. 确认 fb0 可用：
```bash
fbset -fb /dev/fb0
```

2. 检查 X11 日志：
```bash
cat /var/log/Xorg.0.log | grep -i error
cat /var/log/Xorg.0.log | grep fbdev
```

3. 尝试手动指定 framebuffer：
```bash
startx -- -config /etc/X11/xorg.conf.d/20-fbdev.conf
```

### 问题：Console 字体太大/太小
```bash
# 临时更改
setfont /usr/share/consolefonts/Lat15-Terminus12x6.psf.gz

# 永久更改
dpkg-reconfigure console-setup
```

## 参数说明

### fbcon=map 参数详解
- `fbcon=map:1` - console 只在 fb0 (HDMI)
- `fbcon=map:10` - console 只在 fb1 (ST7789)
- `fbcon=map:01` - console 在 fb0 和 fb1 都显示（当前配置）
- `fbcon=map:001` - console 只在 fb2

### 显示输出类型 (output_type)
- `0` - 无输出
- `1` - LCD
- `2` - TV
- `3` - HDMI
- `4` - VGA

### 设备树参数
- `disp_init_enable = 1` - 启用显示初始化
- `screen0_output_type = 3` - HDMI
- `fb0_width/height` - HDMI 分辨率
- `fb1_width/height` - ST7789 分辨率

## 编译和部署

```bash
# 重新编译
./build.sh

# 打包固件
cd build
./pack

# 烧录到设备
# ... 使用你的烧录工具
```

## 配置总结

当前配置实现：
1. ✅ HDMI 正常显示（主显示）
2. ✅ ST7789 作为辅助显示
3. ✅ 启动信息在两个屏幕都显示
4. ✅ 桌面环境使用 HDMI
5. ✅ 可以在 ST7789 上显示终端信息

## 参考资料
- Linux Framebuffer Console: https://www.kernel.org/doc/Documentation/fb/fbcon.txt
- ST7789V Driver: drivers/staging/fbtft/fb_st7789v.c
- Allwinner Display Engine: drivers/video/fbdev/sunxi/disp2/
