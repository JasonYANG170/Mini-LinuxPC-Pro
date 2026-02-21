#!/bin/sh

folder="../../../../rootfile/rootfs/"

FREE=250

mysize=$(du -sm "$folder" | cut -f1)

mysize=$(expr $mysize + $FREE)

echo mysize=${mysize}

cd ../../

# Create mount point if it doesn't exist
mkdir -p mnt

dd if=/dev/zero of=rootfs.ext4 bs=1M count=${mysize}
mkfs.ext4 rootfs.ext4

# Use sudo only if not already root
if [ "$(id -u)" -eq 0 ]; then
    mount rootfs.ext4 mnt
    cp -avrf ../../rootfile/rootfs/* mnt
    sync
    umount mnt
else
    sudo mount rootfs.ext4 mnt
    sudo cp -avrf ../../rootfile/rootfs/* mnt
    sync
    sudo umount mnt
fi
