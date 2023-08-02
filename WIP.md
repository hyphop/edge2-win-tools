# Parts

root@edge2-00000:/# grep mmc proc/mounts 
/dev/mmcblk0p1 /1 vfat rw,relatime,fmask=0022,dmask=0022,codepage=936,iocharset=utf8,shortname=mixed,errors=remount-ro 0 0
root@edge2-00000:/# find 1
1
1/EFI
1/EFI/Boot
1/EFI/Boot/bootaa64.efi
1/EFI/Rufus
1/EFI/Rufus/ntfs_aa64.efi

# eMMC fail boot

                            Windows Boot Manager                               

Windows failed to start. A recent hardware or software change might be the
cause. To fix the problem: 

  1. Insert your Windows installation disc and restart your computer.
  2. Choose your language settings, and then click "Next."
  3. Click "Repair your computer."

If you do not have this disc, contact your system administrator or computer
manufacturer for assistance. 

    File: \EFI\Microsoft\Boot\BCD

    Status: 0xc000000d

    Info: The Boot Configuration Data for your PC is missing or contains    
          errors.                                                           
                                                                            

# USB

/-----------------------------------------------------------------------------\
|                            UEFI:NTFS v2.2 (aa64)                            |
|                            <https://un.akeo.ie>                             |
\-----------------------------------------------------------------------------/

[INFO] UEFI v2.70 (EDK II, 0x00010000)
[INFO] EDK II v0.7.1
[INFO] Khadas Edge2
[INFO] Secure Boot status: Disabled
[INFO] Disconnecting potentially blocking drivers
[INFO] Searching for target partition on boot disk:
[INFO]   VenHw(0D51905B-B77E-452A-A2C0-ECA0CC8D514A,0000D0FC0000000000)/USB(0x1,
0x0)
[INFO] Found NTFS target partition:
[INFO]   VenHw(0D51905B-B77E-452A-A2C0-ECA0CC8D514A,0000D0FC0000000000)/USB(0x1,
0x0)/HD(2,GPT,3514CE46-0037-4A0D-86D1-9E4D3FA190D2,0x45243,0x29BAD9C)
[INFO] Checking if target partition needs the NTFS service
[INFO] Starting NTFS driver service:
[INFO]   NTFS Driver 1.7 (ntfs-3g 69d8cbc0)
[INFO] Opening target NTFS partition:
[INFO]   Volume label is ''
[INFO] This system uses 64-bit ARM UEFI => searching for aa64 EFI bootloader
[INFO] Launching 'EFI\Boot\bootaa64.efi'...

....