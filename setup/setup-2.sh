#!/bin/sh

setup_home_dirs() {
  mkdir -p /home/damien/Contacts
  mkdir -p /home/damien/Desktop
  mkdir -p /home/damien/Downloads
  mkdir -p /home/damien/Documents
  mkdir -p /home/damien/Mail/Perso
  mkdir -p /home/damien/Music
  mkdir -p /home/damien/Notes
  mkdir -p /home/damien/Pictures
  mkdir -p /home/damien/Projects
  mkdir -p /home/damien/Todo
  mkdir -p /home/damien/Videos
}

setup_pass() {
  git clone perso:pass-store ~/.password-store
}

setup_gnupg() {
  curl -sL https://tardypad.me/public_key.txt | gpg --import -
  GPG_PUB_KEY_FINGERPRINT="$( gpg --list-keys --with-colons damien@tardypad.me | awk -F: '/^pub:/ {print $5}' )"
  printf '5\ny\n' | gpg --command-fd 0 --edit-key "${GPG_PUB_KEY_FINGERPRINT}" trust
}

setup_weechat() {
  weechat -ap -r "/secure passphrase $( pass show perso/weechat )" -r '/quit'
}

if [ "$( id -un )" != 'damien' ]; then
  echo 'The script must be run as damien' >&2
  exit 1
fi

setup_home_dirs &&
setup_pass &&
setup_gnupg &&
setup_weechat
