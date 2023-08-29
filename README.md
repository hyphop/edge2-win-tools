# edge2-win-tools

Simple scripts for build Windows ARM installation disk for Khadas Edge2 http://docs.khadas.com/edge2

## Init

    cd ~
    git clone https://github.com/hyphop/edge2-win-tools
    cd edge2-win-tools

## Create blank image

    ./prepare-image

## Prepeare deps

    ./build-prepare

## Build image

    ./build-image

## Write image to Disk

    pv edge2-win-install-arm.img > /dev/sdX && sync

## Clean Up

    ./stop-image                 # unloop image
    rm edge2-win-install-arm.img # remove image
    rm -rf ~/edge2-win-files     # remove cached files (optional)

## Problems


# For Developers

## Delete Windows from eMMC - fast way

    sfdisk --delete /dev/mmcblk0

## Install UEFI to eMMC

+ https://docs.khadas.com/products/sbc/edge2/troubleshooting/edge2-uboot-uefi
+ https://docs.khadas.com/software/oowow/how-to/online-scripts

## Download pre build image

+ http://dl.khadas.com/products/edge2/firmware/.windows/

```
wget http://dl.khadas.com/products/edge2/firmware/.windows/edge2-windows-11-arm.img.zst
zstd -dc edge2-win-install-arm.img.zst > /dev/sdX && sync
```
## Problems

During 1st time Windows Setup ''Shift+F10'' type ''oobe\bypassnro'' press Enter to reboot and skip network request

## Links

+ https://docs.khadas.com/products/sbc/edge2/troubleshooting/windows-install
+ https://docs.khadas.com/products/sbc/edge2/troubleshooting/edge2-uboot-uefi

\#\# hyphop \#\#

