#!/bin/sh

folder="../../../../rootfile/rootfs/"

FREE=250

mysize=$(du -sm "$folder" | cut -f1)

mysize=$(expr $mysize + $FREE)

echo mysize=${mysize}

cd ../../
dd if=/dev/zero of=rootfs.ext4 bs=1M count=${mysize}
mkfs.ext4 rootfs.ext4
sudo -u root mount rootfs.ext4 mnt
sudo -u root cp -avrf ../../rootfile/rootfs/* mnt
sync
sudo -u root umount mnt

