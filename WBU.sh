#!/bin/bash

if [[ $EUID -ne 0 ]]; then
echo "You must be a root user !" 2>&1
exit 1
fi

if [ "$1" = "" ]; then
    echo "USAGE: ./WBU.sh [*.iso] [/dev/sdX] !" 2>&1
exit 1
fi

if [ "$2" = "" ]; then
    echo "USAGE: ./WBU.sh [*.iso] [/dev/sdX] !" 2>&1
exit 1
fi

echo

echo "--- Windows Bootable USB ---" 2>&1
echo "Please ensure that you have installed grub-pc and ntfs-3g !" 2>&1

echo

echo -n "Do you want to calculate md5 of .iso file ? (y/N)? "
read answer
if echo "$answer" | grep -iq "^y" ;then

echo

echo "--- Calculating md5sum of .iso file... ---" 2>&1
md5sum $1

echo

echo -n "Is this md5 correct ? (Y/n)? "
read answer1
if echo "$answer1" | grep -iq "^n" ;then
    exit 1
fi
fi

echo

echo "--- Checking & Unmounting partitions... ---" 2>&1

umount $1
umount $2"1"
umount $2

echo

echo "--- Making msdos label... ---" 2>&1
parted $2 mklabel msdos

echo

echo "--- Making ntfs filesystem... ---" 2>&1
parted $2 mkpart primary ntfs 0% 100% 
mkntfs -Q -v -F -L "Win" $2"1"
parted $2 set 1 boot on

echo

echo "--- Mounting... ---" 2>&1
mount $1 /mnt/iso
mount $2"1" /mnt/usb

echo

echo "\/ This will take a long time, Go to make some coffee :3 \/" 2>&1

echo

echo "--- Copying data... ---" 2>&1
cp -R /mnt/iso/* /mnt/usb/

echo

echo "--- Installing grub... ---" 2>&1
mkdir /mnt/usb/boot
grub-install --force --recheck --target=i386-pc --boot-directory="/mnt/usb/boot" $2

echo

echo "--- Writing grub.cfg... ---" 2>&1
u=$(lsblk -no UUID $2"1")

cat > /mnt/usb/boot/grub/grub.cfg <<EOF

insmod ntfs
insmod search_fs_uuid  
search --no-floppy --fs-uuid $u --set root 
ntldr /bootmgr
boot

EOF

echo

echo "DONE!" 2>&1

exit 1
