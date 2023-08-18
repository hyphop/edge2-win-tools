# edge2-win-tools

WIP: .... testing .....

# Init

    cd ~
    git clone https://github.com/hyphop/edge2-win-tools
    cd edge2-win-tools

# Create blank image

    ./prepare-image

# Prepeare deps

    ./build-prepare

# Build image

    ./build-image

# Write image to Disk

    pv edge2-win-install-arm.img > /dev/sdX

# Limitation

    * Boot only from USB

# Clean Up

    ./stop-image                 # unloop image
    rm edge2-win-install-arm.img # remove image
    rm -rf ~/edge2-win-files     # remove cached files (optional)

# For Developers

## Delete Windows from eMMC - fast way

    sfdisk --delete /dev/mmcblk0

## Install UEFI to eMMC

    https://docs.khadas.com/products/sbc/edge2/troubleshooting/edge2-uboot-uefi

\#\# hyphop \#\#


