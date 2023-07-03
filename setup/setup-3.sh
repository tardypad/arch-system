#!/bin/sh

configure_lxd() {
  systemctl start lxd.service
  lxd init --minimal
}

configure_proxy() {
  # creates keys for CA and trust it
  useradd -m proxyer
  timeout 1s doas -u proxyer mitmproxy
  trust anchor --store /home/proxyer/.mitmproxy/mitmproxy-ca.pem

  # reuse same keys locally (creating new ones seems to create issues on usage)
  cp -r /home/proxyer/.mitmproxy/ /home/damien/.mitmproxy
  chown -R damien:damien /home/damien/.mitmproxy
}

if [ "$( id -un )" != 'root' ]; then
  echo 'The script must be run as root' >&2
  exit 1
fi

configure_lxd &&
configure_proxy
