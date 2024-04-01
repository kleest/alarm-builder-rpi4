#!/bin/bash
set -Eeuxo pipefail

INSTALL_DIR="/build/chroot"
cd /build/

# cleanup all files in INSTALL_DIR
shopt -s dotglob
rm -rf "$INSTALL_DIR/"*

# populate host with archlinuxarm keys so pacstrap succeeds
pacman-key --verbose --init
# fix for https://archlinuxarm.org/forum/viewtopic.php?f=15&t=16701
sed -i '1iallow-weak-key-signatures' "/etc/pacman.d/gnupg/gpg.conf"
pacman-key --verbose --populate archlinux
pacman-key --verbose --populate-from keyrings --populate archlinuxarm


# to allow unshare for root
usermod --add-subuids 100000-165535 --add-subgids 100000-165535 root

# make INSTALL_DIR a mountpoint
mount --bind "${INSTALL_DIR}" "${INSTALL_DIR}"

# bootstrap the system
pacstrap -C pacman.conf -c -G -K -M "$INSTALL_DIR" base linux-aarch64 linux-firmware firmware-raspberrypi uboot-raspberrypi raspberrypi-bootloader openssh archlinuxarm-keyring

# fix for https://archlinuxarm.org/forum/viewtopic.php?f=15&t=16701
sed -i '1iallow-weak-key-signatures' "$INSTALL_DIR/etc/pacman.d/gnupg/gpg.conf"

# fix locales
sed -i 's|#en_US.UTF-8|en_US.UTF-8|g' "$INSTALL_DIR/etc/locale.gen" && sed -i 's|#C.UTF-8|C.UTF-8|g' "$INSTALL_DIR/etc/locale.gen"
arch-chroot "${INSTALL_DIR}" locale-gen

# create initramfs
# fix for https://archlinuxarm.org/forum/viewtopic.php?f=15&t=16672&start=60
sed -i 's/ kms//g' "${INSTALL_DIR}/etc/mkinitcpio.conf"
arch-chroot "${INSTALL_DIR}" mkinitcpio -p linux-aarch64

# configure applications
arch-chroot "${INSTALL_DIR}" systemctl enable sshd

# user configuration
arch-chroot "${INSTALL_DIR}" sh -c 'useradd -m alarm && echo "alarm" | passwd --stdin alarm'
arch-chroot "${INSTALL_DIR}" sh -c 'echo "root" | passwd --stdin root'

# network configuration
cp en.network eth.network "${INSTALL_DIR}/etc/systemd/network/"
arch-chroot "${INSTALL_DIR}" systemctl enable systemd-networkd.service
arch-chroot "${INSTALL_DIR}" systemctl enable systemd-resolved.service

# reset pacman config and keyring
# save mirrorlist
cp "${INSTALL_DIR}/etc/pacman.d/mirrorlist" mirrorlist
rm -rf "${INSTALL_DIR}/etc/pacman.d/"
mkdir -p "${INSTALL_DIR}/etc/pacman.d/gnupg/"
# fix for https://archlinuxarm.org/forum/viewtopic.php?f=15&t=16701
cp gpg.conf "${INSTALL_DIR}/etc/pacman.d/gnupg/gpg.conf"
# restore mirrorlist
mv mirrorlist "${INSTALL_DIR}/etc/pacman.d/mirrorlist"

# fstab
echo "/dev/mmcblk1p1  /boot   vfat    defaults        0       0" >> "$INSTALL_DIR/etc/fstab"

# cleanup
rm -rf "${INSTALL_DIR}/var/cache/pacman/"
