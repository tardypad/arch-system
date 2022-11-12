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
WIFI_DEVICE='wlan0'
BOOT_SIZE='300M'
SWAP_SIZE='2G'
ROOT_SIZE='30G'

# Required inputs
WIFI_SSID=
WIFI_PWD=
DEVICE=
PKG_PWD=
SYSTEM_CONFIG=
HOSTNAME=

# Defined afterwards
EFI_PARTITION=
LUKS_PARTITION=
LUKS_PARTITION_UUID=

connect_to_internet() {
  while [ -z "${WIFI_SSID}" ]; do
    printf 'Enter WiFi SSID: '
    read -r WIFI_SSID
  done

  while [ -z "${WIFI_PWD}" ]; do
    printf 'Enter WiFi password: '
    read -r WIFI_PWD
  done

  printf 'Connecting to WIFI...'
  if ! iwctl --passphrase "${WIFI_PWD}" station "${WIFI_DEVICE}" connect "${WIFI_SSID}" > /dev/null; then
    printf 'failed\n'
    return 1
  fi
  printf 'success\n'

  printf 'Testing Internet connection...'
  if ! ping -c 1 archlinux.org > /dev/null; then
    printf 'failed\n'
    return 1
  fi
  printf 'success\n'
}

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

  printf 'Confirm installation on device %s' "${DEVICE}"
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
}

install_system_config() {
  while [ -z "${PKG_PWD}" ]; do
    printf 'Enter pkgs.tardypad.me HTTP password: '
    read -r PKG_PWD
  done

  printf 'Refresh packages database\n'
  cat >> /etc/pacman.conf <<- EOF
		[tardypad]
		SigLevel = Never
		Server = https://damien:${PKG_PWD}@pkgs.tardypad.me/arch/tardypad

		[aur]
		SigLevel = Never
		Server = https://damien:${PKG_PWD}@pkgs.tardypad.me/arch/aur
	EOF
  pacman -Sy

  printf 'Available system configs:\n'
  pacman -Slq tardypad | sed -n 's/system-config-\(.*\)/- \1/p'
  while [ -z "${SYSTEM_CONFIG}" ]; do
    printf 'Enter system config: '
    read -r SYSTEM_CONFIG
  done

  pacstrap -K /mnt "system-config-${SYSTEM_CONFIG}" --override '*'
}

generate_fstab() {
  genfstab -U /mnt >> /mnt/etc/fstab
}

configure_timezone() {
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

configure_root() {
  printf 'Set root password\n'
  arch-chroot /mnt passwd
}

configure_bootloader() {
  LUKS_PARTITION_UUID="$( blkid -s UUID -o value "${LUKS_PARTITION}" )"
  sed -i "s|^GRUB_CMDLINE_LINUX=.*|GRUB_CMDLINE_LINUX=cryptdevice=UUID=${LUKS_PARTITION_UUID}:cryptlvm root=/dev/vg/root|" /mnt/etc/default/grub
  arch-chroot /mnt grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
  arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg
}

connect_to_internet &&
update_clock &&
prepare_device &&
install_system_config &&
generate_fstab &&
configure_timezone &&
configure_locale &&
configure_hostname &&
configure_initramfs &&
configure_root &&
configure_bootloader