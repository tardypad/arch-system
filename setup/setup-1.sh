#!/bin/sh

# Characteristics:
# - assume UEFI boot mode
# - do not keep any existing bootloader
# - use default US console keymap
# - connect to Internet via WiFi
# - use single disk assumed to be big enough
# - do not wipe disk
# - use LVM on LUKS with unencrypted boot

# Values that should be mostly fixed
LOCALE='en_US.UTF-8'
TIMEZONE='Europe/Madrid'
BOOT_SIZE='300M'
SWAP_SIZE='2G'
ROOT_SIZE='30G'

# Required inputs
DEVICE=
PKG_PWD=
SYSTEM_CONFIG=
HOSTNAME=

# Defined afterwards
EFI_PARTITION=
LUKS_PARTITION=
LUKS_PARTITION_UUID=

update_clock() {
  timedatectl set-ntp true
  timedatectl status
  printf 'Confirm date and time\n'
  read -r
}

prepare_device() {
  printf 'Available devices:\n'
  lsblk -l -o TYPE,NAME,SIZE | sed -n 's/disk */- /p'
  while [ -z "${DEVICE}" ]; do
    printf 'Enter device: '
    read -r DEVICE
  done
  printf '\n'

  DEVICE="/dev/${DEVICE}"

  printf 'Confirm installation on device %s\n' "${DEVICE}"
  read -r

  sgdisk -Z "${DEVICE}"
  sgdisk -n 1:0:+"${BOOT_SIZE}" -t 1:ef00 "${DEVICE}"
  sgdisk -n 2 "${DEVICE}"

  if echo "${DEVICE}" | grep -q nvme; then
    EFI_PARTITION="${DEVICE}p1"
    LUKS_PARTITION="${DEVICE}p2"
  else
    EFI_PARTITION="${DEVICE}1"
    LUKS_PARTITION="${DEVICE}2"
  fi

  cryptsetup luksFormat --verify-passphrase "${LUKS_PARTITION}"
  cryptsetup luksOpen  "${LUKS_PARTITION}" cryptlvm

  pvcreate /dev/mapper/cryptlvm
  vgcreate vg /dev/mapper/cryptlvm
  lvcreate -L "${SWAP_SIZE}" vg -n swap
  lvcreate -L "${ROOT_SIZE}" vg -n root
  lvcreate -l 100%FREE vg -n home

  mkfs.fat -F 32 "${EFI_PARTITION}"
  mkfs.ext4 /dev/vg/root
  mkfs.ext4 /dev/vg/home
  mkswap /dev/vg/swap

  mount /dev/vg/root /mnt
  mount --mkdir /dev/vg/home /mnt/home
  mount --mkdir "${EFI_PARTITION}" /mnt/boot
  swapon /dev/vg/swap

  lsblk -o NAME,TYPE,FSTYPE,SIZE,MOUNTPOINTS
  printf 'Confirm device preparation\n'
  read -r
}

install_system_config() {
  while [ -z "${PKG_PWD}" ]; do
    printf 'Enter pkgs.tardypad.me HTTP password: '
    read -r PKG_PWD
  done
  printf '\n'

  printf 'Refresh packages database\n'
  cat >> /etc/pacman.conf <<- EOF
		[tardypad]
		SigLevel = Never
		Server = https://damien:${PKG_PWD}@pkgs.tardypad.me/arch/tardypad

		[aur]
		SigLevel = Never
		Server = https://damien:${PKG_PWD}@pkgs.tardypad.me/arch/aur
	EOF
  sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf
  pacman -Sy

  printf 'Available system configs:\n'
  pacman -Slq tardypad | sed -n 's/system-config-\(.*\)/- \1/p'
  while [ -z "${SYSTEM_CONFIG}" ]; do
    printf 'Enter system config: '
    read -r SYSTEM_CONFIG
  done
  printf '\n'

  pacstrap -K -i /mnt "system-config-${SYSTEM_CONFIG}" --overwrite '*'

  # we set the packages password on the end system while we can
  sed -i "s/{PASSWORD}/${PKG_PWD}/" /mnt/etc/pacman.d/chestnut

  printf 'Confirm system config installation\n'
  read -r
}

generate_fstab() {
  genfstab -U /mnt >> /mnt/etc/fstab

  cat /mnt/etc/fstab
  printf 'Confirm fstab file\n'
  read -r
}

configure_time() {
  arch-chroot /mnt ln -sf "/usr/share/zoneinfo/${TIMEZONE}" /etc/localtime
  arch-chroot /mnt hwclock --systohc
}

configure_locale() {
  arch-chroot /mnt sed -i "s/#$LOCALE/${LOCALE}/" /etc/locale.gen
  arch-chroot /mnt locale-gen
  echo "LANG=${LOCALE}" > /mnt/etc/locale.conf
}

configure_hostname() {
  while [ -z "${HOSTNAME}" ]; do
    printf 'Enter hostname: '
    read -r HOSTNAME
  done
  printf '\n'

  echo "${HOSTNAME}" > /mnt/etc/hostname

  cat > /mnt/etc/hosts <<- EOF
		127.0.0.1      localhost
		::1            localhost
		127.0.1.1      ${HOSTNAME}
	EOF
}

configure_initramfs() {
  sed -i 's/^HOOKS=.*/HOOKS=(base udev autodetect keyboard keymap consolefont modconf block encrypt lvm2 filesystems fsck)/' /mnt/etc/mkinitcpio.conf
  arch-chroot /mnt mkinitcpio -P
}

configure_users() {
  arch-chroot /mnt useradd -U damien
  arch-chroot /mnt usermod -aG uucp,video,wheel,input,wireshark,lxd damien

  arch-chroot /mnt chsh -s /usr/bin/zsh root
  arch-chroot /mnt chsh -s /usr/bin/zsh damien

  arch-chroot /mnt passwd root
  arch-chroot /mnt passwd damien
}

configure_bootloader() {
  LUKS_PARTITION_UUID="$( blkid -s UUID -o value "${LUKS_PARTITION}" )"

  sed -e "s|^GRUB_CMDLINE_LINUX=.*|GRUB_CMDLINE_LINUX=\"cryptdevice=UUID=${LUKS_PARTITION_UUID}:cryptlvm root=/dev/vg/root\"|" \
      -e 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=3/' \
      -e 's/^GRUB_TIMEOUT_STYLE=.*/GRUB_TIMEOUT_STYLE=hidden/' \
      -i /mnt/etc/default/grub

  arch-chroot /mnt grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
  arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg
}

configure_mount_devices() {
  for d in toshiba lacie tdk_secret tdk_data kobo; do
    mkdir "/mnt/mnt/$d"
  done

  cat >> /mnt/etc/fstab <<- EOF

		# mount-device
		/dev/mapper/toshiba    /mnt/toshiba    ext4 noauto,user
		/dev/mapper/lacie      /mnt/lacie      ext4 noauto,user
		/dev/mapper/tdk_secret /mnt/tdk_secret ext4 noauto,user
		UUID=AFE8-B122         /mnt/tdk_data   vfat noauto,user
		UUID=5BBA-D17          /mnt/kobo       vfat noauto,user
	EOF
}

enable_services() {
  arch-chroot /mnt systemctl enable NetworkManager.service
  arch-chroot /mnt systemctl enable bluetooth.service

  # packages cache cleaning
  arch-chroot /mnt systemctl enable paccache.timer

  # Yubikey usage
  arch-chroot /mnt systemctl enable pcscd.service
}

unmount() {
  umount -R /mnt
}

update_clock &&
prepare_device &&
install_system_config &&
generate_fstab &&
configure_time &&
configure_locale &&
configure_hostname &&
configure_initramfs &&
configure_users &&
configure_bootloader &&
configure_mount_devices &&
enable_services &&
unmount
