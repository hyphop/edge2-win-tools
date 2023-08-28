#!/bin/bash

#- workli MOD https://github.com/buddyjojo/workli 
#  ## hyphop ##

# set default variables

worklitmp=${worklitmp:-/tmp/workli}

DIR=$PWD

echo "TMP-DIR: $worklitmp"

# uncomment for using local files instead of auto download (use alongside $cache after first run to use cached files from previous runs)
# uselocal="1"

# uncomment to not delete the tmp folder at the end (recommended to be used alongside $uselocal)
# cache="1"

# https://dl.radxa.com/rock5/sw/images/loader/rock-5b/rk3588_spl_loader_v1.08.111.bin
export spload="$worklitmp/rk3588_spl_loader_v1.08.111.bin"
# https://github.com/edk2-porting/edk2-rk35xx/releases
export efi="$worklitmp/RK3588_NOR_FLASH_REL.img" 
export efiURL=${efiURL:-https://github.com/edk2-porting/edk2-rk3588/suites/15541896185/artifacts/886911610}

# https://github.com/pbatard/uefi-ntfs/releases
export uefntf="$worklitmp/bootaa64.efi"
# https://github.com/pbatard/ntfs-3g/releases
export uefntfd="$worklitmp/ntfs_aa64.efi" 

# https://github.com/buddyjojo/workli/tree/master/files
#export pei="$worklitmp/worklipe.cmd"
export pei="$DIR/worklipe.cmd"
export bexec="$worklitmp/batchexec.exe" # ^
export bcd="$worklitmp/BCD" # ^

export filepefiles="$worklitmp/pe-files.zip" # used for auto download only

echo "[i] DISK: $disk < $IMAGE">&2

[ "$DEBUG" ] && set -x

debug() {
 echo -e "\e[1;36m[DEBUG]\e[0m $1" >&2
}
error() {
 echo -e "\e[1;31m[ERROR]\e[0m $1" >&2
 exit 1
}
FAIL(){
    echo "[e] $@">&2
    exit 1
}

SUDO(){
    echo "SUDO $@">&2
    sudo "$@" || exit 1
}

CHK(){
    which $1 || FAIL need install ${2:-$1}
}

CMD(){
    echo "# $@">&2
    "$@"
}
CMD2(){
    echo "# $@">&2
    "$@" || exit 1
}

FIND(){
local a
for a in "$@"; do
    [ -f "$a" ] || FAIL "not found ${a##*/}"
    echo "[i] chk ${a##*/}">&2
done
}

[ "$EUID" -ne 0 ] && FAIL need root perms

CHK wimupdate wimtools
CHK parted
CHK mkfs.ntfs ntfs-3g
CHK gawk
CHK xmlstarlet
CHK wget
CHK aria2c aria2
CHK curl
CHK jq

# CHK rkdeveloptool ???

mkdir -p $worklitmp
chmod 777 $worklitmp


if [[ $uselocal == *"1"* ]]; then

    debug "uselocal set to 1, skipping auto download..."

else

    wget -O "$uefntf" \
    "https://github.com/pbatard/uefi-ntfs/releases/latest/download/bootaa64.efi" \
    || FAIL "Failed to download bootaa64.efi from pbatard/uefi-ntfs"
    wget -O "$uefntfd" \
    "https://github.com/pbatard/ntfs-3g/releases/latest/download/ntfs_aa64.efi" \
    || FAIL "Failed to download ntfs_aa64.efi from pbatard/ntfs-3g"
    wget -O "$filepefiles" \
    "https://github.com/buddyjojo/workli/releases/latest/download/y-pe-files.zip" \
    || FAIL "Failed to download y-pe-files.zip from buddyjojo/workli"

    unzip -o "$filepefiles" BCD batchexec.exe -d "$worklitmp/"

    UEFI_LATEST=https://api.github.com/repos/edk2-porting/edk2-rk35xx/releases/latest

    [ "$efiURL" ] || {
    gitjson=$(curl -L "$UEFI_LATEST")
    efiFILE=$(echo $gitjson | jq -r '.assets[] | .name' | grep edge2)
    echo $efiFILE
    efiURL=$(echo $gitjson | jq --arg efifile "$efiFILE" -r '.assets[] | select( .name | match($efifile)) | .browser_download_url ') #'
    }

    CMD wget -O "$efi" "$efiURL" \
	|| FAIL "Failed to download RK3588_NOR_FLASH_REL.img"

    export auto=1
fi

winver=$worklitmp/winver.xml

FIND $uefntf $uefntfd $pei $bexec $bcd $efi

[ -s "$winver" ] || \
    CMD2 curl -o$winver -s -G 'https://worproject.com/dldserv/esd/getversions.php'

WIN_VERS=$(cat $winver | xmlstarlet sel -t -v /productsDb/versions/version/@number)
debug "Windows versions: $WIN_VERS"

[ "$winversion" ] || \
winversion=$(cat $winver | xmlstarlet sel -t -v /productsDb/versions/*[1]/@number - )

debug "Windows version is $winversion"

WIN_BUILDS=$(echo $(cat $winver | xmlstarlet sel -t -m /productsDb/versions/version[@number=$winversion]/releases/release -o " " -v ./@build -o " " -))

debug "Windows builds: $WIN_BUILDS"

[ "$winbuild" ] || winbuild=${WIN_BUILDS%% *}

debug "Windows build is $winbuild"

winlist=$worklitmp/winlist.xml

[ -s "$winlist" ] || \
CMD2 curl -o $winlist -s -G 'https://worproject.com/dldserv/esd/getcatalog.php' \
    -d arch=ARM64 -d ver=$winversion -d build=$winbuild

WIN_LIST=$(echo $(cat $winlist | xmlstarlet sel -t -m "/MCT/Catalogs/Catalog/PublishedMedia/Files/File[not(./Edition_Loc=preceding-sibling::File/Edition_Loc)]" -o " " -v "Edition_Loc" -o " " - | sed s/%//g))

debug "Windows list: $WIN_LIST"

[ "$winedition" ] || winedition=${WIN_LIST%% *}

debug "Windows edition is $winedition"

WIN_LANGS=$(cat $winlist | xmlstarlet sel -t -v /MCT/Catalogs/Catalog/PublishedMedia/Files/File/Language )

#debug "Windows langs: $WIN_LANGS"

winlanguage=${winlanguage:-default}

[ "$winlanguage" ] || {
    winlanguage=${winlanguage:-English (United States)}
    winlanguage=${winlanguage:-default}
    [ "$winlangcode" ] || \
    winlangcode=$(cat $winlist | xmlstarlet sel -t -m "/MCT/Catalogs/Catalog/PublishedMedia/Files/File[Language='$winlanguage' and Edition_Loc='%$winedition%']" -v LanguageCode - )
}

winlangcode=${winlangcode:-en-us}
winlanguage=${winlanguage:-default}

debug "Windows language is $winlanguage, lang code is $winlangcode"

esdurl=$(cat $winlist | xmlstarlet sel -t -m "/MCT/Catalogs/Catalog/PublishedMedia/Files/File[LanguageCode='$winlangcode' and Edition_Loc='%$winedition%']" -v FilePath - )

#'"

debug "ESD link is $esdurl"

export esdpth="$worklitmp"

iso="$esdpth/win.esd"

[ -f "$iso" ] && \
CMD2 chmod 0777 $iso

[ -f "$iso.aria2" ] && \
CMD2 chmod 0777 $iso.aria2

[ -f "$iso.aria2" -o ! -f "$iso" ] && {
    CMD2 aria2c -d "$esdpth" -o "win.esd" "$esdurl"
}

CMD2 chmod 0777 $iso

export esd=1

CHK cabextract
CHK chntpw
CHK mkisofs
CHK genisoimage

if [[ -f "$iso" ]]; then
    debug "win.iso/install.wim/win.esd found"
else
    error "win.iso/install.wim/win.esd does not exist. The iso variable was set to $iso"
fi

if [[ $iso =~ \.[Ww][Ii][Mm]$ ]]; then
    export fulliso=0
    export esd=0
    debug "WIM detected = $fulliso, $iso"
    typexml=$(wiminfo --xml $iso | xmlstarlet fo)
elif [[ $iso =~ \.[Ee][Ss][Dd]$ ]]; then
    export esd=1
    export fulliso=0
    debug "ESD detected = $esd, $iso"
    typexml=$(wiminfo --xml $iso | xmlstarlet fo)
else
    export fulliso=1
    export esd=0
    debug "Full ISO detected = $fulliso, $iso"

    debug "Mounting ISO for type selection"

    mkdir -p "$worklitmp/isomount"
    chmod 777 "$worklitmp/isomount"

    mount "$iso" "$worklitmp/isomount"

    typexml=$(wiminfo --xml "$worklitmp/isomount/sources/install.*" | xmlstarlet fo)

    umount "$worklitmp/isomount"

    rm -rf "$worklitmp/isomount"
fi

#windtype=$(
echo WIND_TYPE
echo "$typexml"  | xmlstarlet sel -t -v /WIM/IMAGE/NAME
echo
# | gawk '{ printf "FALSE""\0"$0"\0" }' | sed 's/\(.*\)FALSE/\1TRUE/' |zenity --list --title="workli" --text="What windows type do you want?\n\nNote: some windows types may not be bootable" --radiolist --multiple --column ' ' --column 'Windows type' --width=300 --height=300
#)

windtype=${windtype:-Windows 11 Pro}

wintype=$(echo "$typexml" | xmlstarlet sel -t -v "/WIM/IMAGE[NAME='$windtype']/@INDEX") #'"

debug "wintype(index) is $wintype"

[ "$disk" ] || {
    debug "Prepare stage is done, need setup disk"
    exit 0
}

if [[ $disk == *"mmcblk"* ]]; then
    export nisk="${disk}p"
else
    export nisk="$disk"
fi

if [[ $disk == *"disk"* ]]; then
    export nisk="${disk}s"
else
    export nisk="$disk"
fi

if [[ $disk == *"loop"* ]]; then
    export nisk="${disk}p"
else
    export nisk="$disk"
fi

if [[ -b "/dev/$disk" ]]; then
   debug "$disk found"
else
   error "DISK $disk does not exist."
fi

#(

debug "Creating partitions..."

umount /dev/$disk*

CMD2 parted -s /dev/$disk mklabel gpt
CMD2 parted -s /dev/$disk mkpart primary ${P1O:-20MB} 128MB

debug "Write UEFI bootloader..."
CMD2 dd skip=2048 seek=$((0x4000)) count=$((0x4000)) of=/dev/$disk if=$efi conv=fsync,notrunc

CMD2 parted -s /dev/$disk set 1 esp on
CMD2 parted -s /dev/$disk set 1 boot on

CMD2 parted -s -- /dev/$disk mkpart primary 145MB -0
CMD2 parted -s /dev/$disk set 2 msftdata on

sync
CMD2 mkfs.fat -F 32 /dev/$nisk'1'
sync

CMD2 mkfs.ntfs -f /dev/$nisk'2'
sync

debug "Copying Windows files to the drive."

if [[ $fulliso == *"1"* ]]; then

CMD2 mkdir -p "$worklitmp/isomount"
CMD2 chmod 777 "$worklitmp/isomount"
CMD2 mount "$iso" "$worklitmp/isomount"
CMD2 wimapply --check "$worklitmp/isomount/sources/install.*" $wintype /dev/$nisk'2' >&2
CMD2 umount "$worklitmp/isomount"
CMD2 rm -rf "$worklitmp/isomount"

else
CMD2 wimapply --check "$iso" $wintype /dev/$nisk'2' >&2
fi

echo "# Mounting partitions..."

CMD2 mkdir -p "$worklitmp/bootpart" "$worklitmp/winpart"

CMD2 mount /dev/$nisk'1' "$worklitmp/bootpart"
CMD2 mount /dev/$nisk'2' "$worklitmp/winpart"

echo "# Copying boot files..."

CMD2 mkdir -p "$worklitmp/bootpart/EFI/Boot/"
CMD2 mkdir -p "$worklitmp/bootpart/EFI/Rufus/"

debug "${uefntf}, ${uefntfd}"

CMD2 cp ${uefntf} "$worklitmp/bootpart/EFI/Boot/"
CMD2 cp ${uefntfd} "$worklitmp/bootpart/EFI/Rufus/"

CMD2 mkdir -p "$worklitmp/winpart/EFI/Boot/"
CMD2 mkdir -p "$worklitmp/winpart/EFI/Microsoft/Boot/Resources"

CMD2 cp "$worklitmp/winpart/Windows/Boot/EFI/bootmgfw.efi" "$worklitmp/winpart/EFI/Boot/bootaa64.efi"
CMD2 cp ${bcd} "$worklitmp/winpart/EFI/Microsoft/Boot/BCD"
CMD2 cp "$worklitmp/winpart/Windows/Boot/EFI/winsipolicy.p7b" "$worklitmp/winpart/EFI/Microsoft/Boot/winsipolicy.p7b"
CMD2 cp "$worklitmp/winpart/Windows/Boot/Resources/bootres.dll" "$worklitmp/winpart/EFI/Microsoft/Boot/Resources/bootres.dll"
CMD2 cp -r "$worklitmp/winpart/Windows/Boot/EFI/CIPolicies" "$worklitmp/winpart/EFI/Microsoft/Boot/"
CMD2 cp -r "$worklitmp/winpart/Windows/Boot/Fonts" "$worklitmp/winpart/EFI/Microsoft/Boot/"


winrewim=$(find "$worklitmp/winpart/Windows/System32/Recovery/" -type f -name [Ww]inre.wim)

echo "# Editing WinRE... $winrewim"

CMD2 cp "$winrewim" "$worklitmp/winpart/Windows/System32/Recovery/backup-winre.wim"
CMD2 wimupdate "$winrewim" 1 --command="add ${pei} /worklipe.cmd"
CMD2 wimupdate "$winrewim" 1 --command="delete /sources/recovery/RecEnv.exe"
CMD2 wimupdate "$winrewim" 1 --command="add ${bexec} /sources/recovery/RecEnv.exe"
CMD2 wimupdate "$winrewim" 1 --command="add $worklitmp/driverpackage /driverpackage"

#errors="$(sudo wimupdate "$mntpnt"/bootpart/sources/boot.wim 2 --command="add driverpackage /drivers" 2>&1)" || error "The wimupdate command failed to add $PWD/driverpackage to boot.wim\nErrors:\n$errors"

debug press any key

read YES

debug "Unmounting drive"

sync

case $disk in
    sd*)
CMD2 umount /dev/${disk}*
    ;;
    *)
CMD2 umount /dev/${disk}p*
    ;;
esac

[ "" ] && {
echo "# Cleaning up..."

if [[ $cache == *"1"* ]]; then
    debug "cache set to 1, skipping tmp deletion"
    debug "uncomment uselocal at top of script to use cached files"
else
    rm -rf "$worklitmp/"
fi

if [[ $deluup == *"1"* ]]; then
    rm -rf "$uuproot/uup"
else
    debug "UUPs set to not be deleted"
fi

if [[ $delesd == *"1"* ]]; then
    rm -rf "$esdpth"
else
    debug "ESD set to not be deleted"
fi

}

echo "# Press OK to continue"

#)

debug "It has finnished"

exit
