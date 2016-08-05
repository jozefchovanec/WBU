#!/bin/bash

if [[ $EUID -ne 0 ]]; then
echo "You must be a root user !" 2>&1
exit 1
fi

if [ "$1" = "" ]; then
    echo "USE: ./WBU.sh [*.iso] [/dev/sdx] !" 2>&1
exit 1
fi

if [ "$2" = "" ]; then
    echo "USE: ./WBU.sh [*.iso] [/dev/sdx] !" 2>&1
exit 1
fi

echo " " 2>&1
echo "--- Windows Bootable USB ---" 2>&1
echo "Please ensure that you have installed grub-pc and ntfs-3g !" 2>&1
echo " " 2>&1

echo "--- Calculating md5sum of .iso file... ---" 2>&1
md5sum $1

echo " " 2>&1

echo -n "Is this md5 correct ? (Y/n)? "
read answer
if echo "$answer" | grep -iq "^n" ;then
    exit 1
fi

echo " " 2>&1

echo "--- Checking & Unmounting partitions... ---" 2>&1

umount $1
umount $2"1"
umount $2

echo " " 2>&1

echo "--- Making msdos label... ---" 2>&1
parted $2 mklabel msdos

echo " " 2>&1

echo "--- Making ntfs filesystem... ---" 2>&1
mkntfs -Q -v -F -L "Win" $2

echo " " 2>&1

echo "--- Mounting... ---" 2>&1
mount $1 /mnt/iso
mount $2 /mnt/usb

echo " " 2>&1

echo "--- Installing grub... ---" 2>&1
mkdir /mnt/usb/boot
grub-install --force -v --recheck --target=i386-pc --boot-directory="/mnt/usb/boot" $2

echo " " 2>&1

echo "--- Copying data... ---" 2>&1
cp -R -v /mnt/iso/ /mnt/usb/

echo " " 2>&1

echo "--- Writing grub.cfg... ---" 2>&1
u=$(lsblk -no UUID $2)

cat > /mnt/usb/boot/grub/grub.cfg <<EOF

insmod ntfs
insmod search_fs_uuid  
search --no-floppy --fs-uuid $u --set root 
ntldr /bootmgr
boot

EOF

echo " " 2>&1

echo "--- Checking & Unmounting partitions... ---" 2>&1
umount $1
umount $2"1"
umount $2

echo " " 2>&1

echo "DONE!" 2>&1

exit 1
