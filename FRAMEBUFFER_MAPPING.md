# H618 Framebuffer 设备映射说明

## 实际设备映射

由于驱动加载顺序，实际的 framebuffer 设备映射如下：

```
/dev/fb0 → ST7789 (320x170) - SPI LCD
/dev/fb1 → HDMI (1920x1080) - 主显示
```

**注意**：这与设备树中的配置顺序相反！

## 为什么会这样？

### 驱动加载顺序

1. **ST7789 驱动** (`drivers/staging/fbtft/`)
   - 通过设备树 SPI 节点加载
   - 作为模块或内置驱动较早初始化
   - 先注册 → 成为 fb0

2. **HDMI 驱动** (`drivers/video/fbdev/sunxi/disp2/`)
   - Allwinner Display Engine 2
   - 后初始化
   - 后注册 → 成为 fb1

### 内核日志示例
```
[    1.234] fbtft: module is from the staging directory
[    1.456] fb_st7789v spi1.0: fb0: fb_st7789v frame buffer device
[    2.789] sunxi_disp 1000000.disp: fb1: disp frame buffer device
```

## 当前配置

### 启动参数
```bash
fbcon=map:10
```

**含义**：
- `map:10` = console 映射到 fb1 (HDMI)
- fb0 (ST7789) 不显示 console，只显示 logo 或自定义内容

### 显示效果

```
┌─────────────────────────────────────┐
│  启动后的显示                        │
├─────────────────────────────────────┤
│  fb0 (ST7789)  → Logo/静态图像      │
│  fb1 (HDMI)    → Console/终端       │
└─────────────────────────────────────┘
```

## 配置选项

### 选项 1: ST7789 显示终端，HDMI 显示桌面（当前配置）
```bash
fbcon=map:10
```
- ST7789: 显示 logo 或自定义内容
- HDMI: 显示 console 和桌面

### 选项 2: HDMI 显示终端，ST7789 显示终端
```bash
fbcon=map:01
```
- ST7789: 显示 console
- HDMI: 显示 console
- 两个屏幕显示相同内容

### 选项 3: 只 ST7789 显示终端
```bash
fbcon=map:1
```
- ST7789: 显示 console
- HDMI: 空闲（可用于桌面）

### 选项 4: 只 HDMI 显示终端
```bash
fbcon=map:10
```
- ST7789: 空闲（显示 logo）
- HDMI: 显示 console

## 使用指南

### 1. 在 ST7789 上显示内容

```bash
# 清屏
cat /dev/zero > /dev/fb0

# 显示图案
cat /dev/urandom > /dev/fb0

# 显示图片
fbi -d /dev/fb0 -T 1 -noverbose -a image.jpg

# 显示文本（需要 fbcon=map:1 或 map:01）
echo "Hello ST7789" > /dev/tty0
```

### 2. 在 HDMI 上显示内容

```bash
# 清屏
cat /dev/zero > /dev/fb1

# 显示图案
cat /dev/urandom > /dev/fb1

# 显示图片
fbi -d /dev/fb1 -T 1 -noverbose -a image.jpg

# 显示文本（需要 fbcon=map:10 或 map:01）
echo "Hello HDMI" > /dev/tty1
```

### 3. 桌面环境配置

#### X11 使用 HDMI (fb1)
创建 `/etc/X11/xorg.conf.d/20-fbdev.conf`:
```
Section "Device"
    Identifier  "HDMI Display"
    Driver      "fbdev"
    Option      "fbdev" "/dev/fb1"
EndSection
```

#### Weston 使用 HDMI (fb1)
编辑 `/etc/weston.ini`:
```ini
[core]
backend=fbdev-backend.so

[output]
name=fb1
mode=1920x1080
```

### 4. ST7789 显示状态信息

由于 ST7789 是 fb0，如果想在上面显示终端，需要：

**方法 1: 修改 fbcon 映射**
```bash
# 在 env.cfg 中设置
fbcon=map:01  # 两个屏幕都显示
# 或
fbcon=map:1   # 只 ST7789 显示
```

**方法 2: 使用 framebuffer 直接写入**
```bash
# 创建状态显示脚本
cat > /usr/local/bin/st7789-status.sh << 'EOF'
#!/bin/bash

# 使用 fbv 或 fbi 显示图片
while true; do
  # 生成状态图片
  convert -size 320x170 -background black -fill white \
    -pointsize 20 -gravity center \
    label:"$(date +%H:%M:%S)\nCPU: $(top -bn1 | grep Cpu | awk '{print $2}')" \
    /tmp/status.png
  
  # 显示到 ST7789
  fbi -d /dev/fb0 -T 1 -noverbose -a /tmp/status.png
  
  sleep 2
done
EOF

chmod +x /usr/local/bin/st7789-status.sh
```

**方法 3: 使用 Python PIL**
```python
#!/usr/bin/env python3
from PIL import Image, ImageDraw, ImageFont
import time
import os

def update_display(text):
    # 创建图像
    img = Image.new('RGB', (320, 170), color='black')
    draw = ImageDraw.Draw(img)
    
    # 添加文本
    font = ImageFont.load_default()
    draw.text((10, 10), text, fill='white', font=font)
    
    # 写入 framebuffer
    with open('/dev/fb0', 'wb') as fb:
        fb.write(img.tobytes())

while True:
    status = f"Time: {time.strftime('%H:%M:%S')}\n"
    status += f"CPU: {os.popen('top -bn1 | grep Cpu').read().split()[1]}"
    update_display(status)
    time.sleep(2)
```

## 验证设备映射

### 检查设备
```bash
# 列出 framebuffer 设备
ls -l /dev/fb*

# 查看设备名称
cat /sys/class/graphics/fb0/name  # 应该显示 fb_st7789v
cat /sys/class/graphics/fb1/name  # 应该显示 disp

# 查看分辨率
fbset -fb /dev/fb0  # 320x170
fbset -fb /dev/fb1  # 1920x1080
```

### 测试显示
```bash
# 测试 ST7789 (fb0)
dd if=/dev/zero bs=1k count=200 | tr '\000' '\377' > /dev/fb0

# 测试 HDMI (fb1)
dd if=/dev/zero bs=1M count=8 | tr '\000' '\377' > /dev/fb1
```

## 常见问题

### Q: 为什么设备顺序和设备树配置不一致？
A: 因为驱动加载顺序决定了 framebuffer 注册顺序，而不是设备树中的定义顺序。

### Q: 如何让 HDMI 成为 fb0？
A: 有几种方法：
1. 将 ST7789 编译为模块，延迟加载
2. 修改驱动初始化顺序
3. 使用 fbcon=map 参数适配当前顺序（推荐）

### Q: 桌面环境应该使用哪个 framebuffer？
A: 使用 fb1 (HDMI)，因为它分辨率更高，适合桌面显示。

### Q: 如何在两个屏幕上显示不同内容？
A: 
- 使用 `fbcon=map:10` 让 console 只在 HDMI 上
- ST7789 通过直接写入 /dev/fb0 显示自定义内容
- 桌面环境使用 fb1 (HDMI)

## 配置总结

### 当前配置 (fbcon=map:10)
```
┌──────────────┐    ┌─────────────────┐
│  ST7789      │    │  HDMI           │
│  (fb0)       │    │  (fb1)          │
│              │    │                 │
│  Logo/       │    │  Console        │
│  自定义内容  │    │  或桌面         │
│              │    │                 │
└──────────────┘    └─────────────────┘
```

### 推荐使用场景
- **开发调试**: `fbcon=map:01` (两个屏幕都显示 console)
- **生产环境**: `fbcon=map:10` (HDMI 显示 console/桌面，ST7789 显示状态)
- **纯桌面**: `fbcon=map:10` + X11/Wayland on fb1

## 修改配置

编辑文件：`device/config/chips/h618/configs/p1/dragonboard/env.cfg`

修改 `fbcon=map:XX` 参数，然后重新编译和打包固件。
